import AuthenticationServices
import StoreKit
import UIKit

@objc(SPTSessionManager)
@objcMembers
public final class SessionManager: NSObject {
    /// The `Session` for the `SessionManager` to manage. If no user has been authenticated this will be nil
    public var session: Session? {
        get {
            sessionLock.lock()
            defer { sessionLock.unlock() }
            return _session
        }
        set {
            sessionLock.lock()
            defer { sessionLock.unlock() }
            _session = newValue
        }
    }

    /// The `SessionManagerDelegate` to notify of getting an authentication code and/or errors related to it.
    public weak var delegate: SessionManagerDelegate?

    private let configuration: Configuration
    private var currentPKCEPair: PKCEPair?
    private var authenticationSession: ASWebAuthenticationSession?
    private var _session: Session?
    private let sessionLock = NSLock()

    /// This is declared internal for testing
    let urlSession: URLSession

    /// Create an `SessionManager` with the provided configuration.
    /// - Parameter configuration: An `Configuration` object.
    /// - Returns An `SessionManager` with the desired configuration.
    public convenience init(configuration: Configuration, delegate: SessionManagerDelegate?) {
        self.init(configuration: configuration, delegate: delegate, urlSession: URLSession(configuration: .ephemeral))
    }

    /// Internal designated initializer for testing purposes
    /// - Parameter configuration: An `Configuration` object.
    /// - Parameter delegate: An optional `SessionManagerDelegate` to receive callbacks.
    /// - Parameter urlSession: A custom `URLSession` for network requests.
    init(configuration: Configuration, delegate: SessionManagerDelegate?, urlSession: URLSession) {
        self.configuration = configuration
        self.delegate = delegate
        self.urlSession = urlSession
        super.init()
    }

    deinit {
        authenticationSession?.cancel()
        authenticationSession = nil
        urlSession.invalidateAndCancel()
    }
}

// MARK: - Public API

public extension SessionManager {
    /// Determine if the Spotify app is installed.
    /// Will be `true` if the Spotify app is installed (and the URL scheme is allowlisted), otherwise is `false`.
    /// Note: You must allowlist the "spotify" URL scheme in your info.plist LSApplicationQueriesSchemes or this will always be `false`
    var isSpotifyAppInstalled: Bool {
        guard let url = URL(string: Constant.Client.urlScheme) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }

    /// start the authorization process
    /// - Parameter scopes: An array of Scope values, e.g. `@[@(SPTScopePlaylistReadPrivate), @(SPTScopePlaylistUserReadEmail)]` if you wish to request read access to private playlists, and read access to the user's email address.
    /// - Parameter authorizationFlow: The authorization flow to use.
    /// - Parameter campaign: The optional campaign identifier, to help attribute where the account linking was initiated from.
    /// See `SessionManagerDelegate` for messages regarding changes in session state.
    @objc(initiateSessionWithScope:authorizationFlow:campaign:)
    func initiateSession(with scopes: [NSNumber], authorizationFlow: AuthorizationFlow, campaign: String?) {
        let scopesArray = scopes.compactMap { Scope(rawValue: $0.intValue) }
        initiateSession(with: scopesArray, authorizationFlow: authorizationFlow, campaign: campaign)
    }

    /// start the authorization process
    /// - Parameter scopes: An array of Scope values, e.g. `[.playlistReadPrivate, .userReadEmail]` if you wish to request read access to private playlists, and read access to the user's email address.
    /// - Parameter authorizationFlow: The authorization flow to use.
    /// - Parameter campaign: The optional campaign identifier, to help attribute where the account linking was initiated from.
    /// See `SessionManagerDelegate` for messages regarding changes in session state.
    func initiateSession(with scopes: [Scope], authorizationFlow: AuthorizationFlow = .default, campaign: String? = nil) {
        // Generate new PKCE pair for this session
        do {
            currentPKCEPair = try PKCEProvider.generatePKCEPair()
        } catch {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return
        }

        guard let authorizationURL = authorizationURL(with: scopes, campaign: campaign) else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return
        }

        switch authorizationFlow {
        case .default:
            // Try app-to-app first, fallback to web session if not installed or fails
            if isSpotifyAppInstalled {
                initiateClientSession(with: authorizationURL, useWebSessionAsFallback: true)
            } else {
                // Spotify not installed, go straight to web session
                initiateWebSession(with: authorizationURL)
            }
            return

        case .clientOnlyRedirectAppStore:
            // Similar to .default but redirect to App Store instead of falling back to web
            initiateClientOnlyRedirectAppStore(with: authorizationURL)
            return

        case .clientOnlyFailsIfNotInstalled:
            // Similar to .default but fails instead of falling back to web
            initiateClientSession(with: authorizationURL, useWebSessionAsFallback: false)
            return

        case .spotifySchemeNotRegistered:
            // Always attempt client session with web fallback
            // Useful when LSApplicationQueriesSchemes is not configured
            initiateClientSession(with: authorizationURL, useWebSessionAsFallback: true)
            return
        }
    }

    /// Handle openURL callbacks from the `AppDelegate`
    /// - Parameter url: The URL to attempt to parse the access token from
    /// @return Returns `true` if `SessionManager` recognizes the URL and will attempt to parse an access token, otherwise returns `false`.
    @objc(openURL:)
    func openURL(_ url: URL) -> Bool {
        return authenticateWithURL(url)
    }

    /// Handle universal links from `UIApplicationDelegate` or `UISceneDelegate`.
    /// This method handles authentication callbacks delivered via NSUserActivity (universal links).
    /// - Parameter userActivity: The user activity object containing the universal link data.
    /// - Returns: `true` if the activity was a web browsing activity and the URL was handled, otherwise `false`.
    @objc(continueUserActivity:)
    func continueUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        return authenticateWithURL(url)
    }

    /// Attempt to renew the access token, using the refresh token in the current `Session` which must be valid.
    @objc(renewSession)
    func renewSession() {
        // Capture session value safely before async operation
        guard let currentSession = session else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.renewSessionFailed)
            return
        }

        // Determine URL based on whether token refresh URL is configured
        guard let url = tokenRefreshURL() else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.renewSessionFailed)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        guard let encodedRefreshToken = currentSession.refreshToken.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.renewSessionFailed)
            return
        }

        let parameters: [String: String] = [
            Constant.OAuth.clientIDParameterName: configuration.clientID,
            Constant.OAuth.grantTypeParameterName: Constant.OAuth.refreshTokenGrantTypeParameterValue,
            Constant.OAuth.refreshTokenParameterName: encodedRefreshToken,
        ]

        request.httpBody = parameters.formURLEncodedData()

        urlSession.dataTask(with: request) { [weak self] data, _, error in
            self?.handleAccessTokenResponse(data: data, error: error, refreshToken: currentSession.refreshToken, isRenewal: true)
        }.resume()
    }
}

// MARK: - Internal

extension SessionManager {

    private func authenticateWithURL(_ url: URL) -> Bool {
        // Cancel any pending authentication session
        authenticationSession?.cancel()

        // First check if the URL matches our redirect URL scheme
        let redirectURL = configuration.redirectURL
        guard url.scheme == redirectURL.scheme,
              url.host == redirectURL.host else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return false
        }

        // Check if redirect URL has a path and validate it matches
        if !redirectURL.path.isEmpty && url.path != redirectURL.path {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return false
        }

        // Extract query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return false
        }

        // Check for error parameter first
        if let error = queryItems.first(where: { $0.name == Constant.OAuth.errorParameterName })?.value {
            // Distinguish between user cancellation and other errors
            if error == Constant.OAuth.userCanceledErrorValue {
                delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationCancelled)
            } else if error == Constant.OAuth.accessDeniedErrorValue {
                delegate?.sessionManager(manager: self, didFailWith: SpotifyError.accessDenied)
            } else {
                delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            }
            return true
        }

        // No error, try to extract authorization code
        guard let authCode = authorizationCode(from: url) else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return false
        }

        requestAccessToken(with: authCode)
        return true
    }

    func requestAccessToken(with authorizationCode: String) {
        // Check if delegate wants to handle the token exchange themselves
        if let shouldRequest = delegate?.sessionManager?(manager: self, shouldRequestAccessTokenWith: authorizationCode),
           !shouldRequest {
            return
        }

        // Determine if we're using token swap or PKCE flow
        if let tokenSwapURL = configuration.tokenSwapURL {
            // Token swap flow - exchange via backend
            requestAccessTokenWithTokenSwap(authorizationCode: authorizationCode, tokenSwapURL: tokenSwapURL)
        } else {
            // PKCE flow - exchange directly with Spotify
            requestAccessTokenWithPKCE(authorizationCode: authorizationCode)
        }
    }

    private func requestAccessTokenWithPKCE(authorizationCode: String) {
        // Exchange authorization code for access token using PKCE
        guard let pkce = currentPKCEPair else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return
        }

        var components = URLComponents(string: Constant.OAuth.serviceOriginURLString)
        components?.path = Constant.OAuth.tokenEndpoint

        guard let url = components?.url else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let parameters: [String: String] = [
            Constant.OAuth.clientIDParameterName: configuration.clientID,
            Constant.OAuth.codeParameterName: authorizationCode,
            Constant.OAuth.codeVerifierParameterName: pkce.codeVerifier,
            Constant.OAuth.grantTypeParameterName: Constant.OAuth.authorizationCodeGrantTypeParameterValue,
            Constant.OAuth.redirectURIParameterName: configuration.redirectURL.absoluteString,
        ]

        request.httpBody = parameters.formURLEncodedData()

        urlSession.dataTask(with: request) { [weak self] data, _, error in
            self?.handleAccessTokenResponse(data: data, error: error, refreshToken: nil, isRenewal: false)
        }.resume()
    }

    private func requestAccessTokenWithTokenSwap(authorizationCode: String, tokenSwapURL: URL) {
        // Exchange authorization code for access token via backend token swap service
        var request = URLRequest(url: tokenSwapURL)
        request.httpMethod = "POST"

        let parameters: [String: String] = [
            Constant.OAuth.codeParameterName: authorizationCode,
        ]

        request.httpBody = parameters.formURLEncodedData()

        urlSession.dataTask(with: request) { [weak self] data, _, error in
            self?.handleAccessTokenResponse(data: data, error: error, refreshToken: nil, isRenewal: false)
        }.resume()
    }

    func handleAccessTokenResponse(data: Data?, error: Error?, refreshToken: String?, isRenewal: Bool) {

        let spotifyError = isRenewal ? SpotifyError.renewSessionFailed : SpotifyError.authorizationFailed

        guard let data, error == nil else {
            delegate?.sessionManager(manager: self, didFailWith: spotifyError)
            return
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                delegate?.sessionManager(manager: self, didFailWith: spotifyError)
                return
            }

            // Check for error in response
            if json[Constant.OAuth.errorParameterName] as? String != nil {
                delegate?.sessionManager(manager: self, didFailWith: spotifyError)
                return
            }

            // Extract session data
            guard let accessToken = json[Constant.OAuth.accessTokenParameterName] as? String,
                  let expiresIn = json[Constant.OAuth.expiresInParameterName] as? TimeInterval,
                  let sessionRefreshToken = json[Constant.OAuth.refreshTokenParameterName] as? String else {
                delegate?.sessionManager(manager: self, didFailWith: spotifyError)
                return
            }
            let expirationDate = Date(timeIntervalSinceNow: expiresIn)

            // Parse scopes
            let scopeString = json[Constant.OAuth.scopeParameterName] as? String ?? ""
            let scopes = Scope.scopes(from: scopeString)

            let newSession = Session(
                accessToken: accessToken,
                refreshToken: sessionRefreshToken,
                expirationDate: expirationDate,
                scopes: scopes
            )

            self.session = newSession

            if isRenewal {
                delegate?.sessionManager?(manager: self, didRenew: newSession)
            } else {
                delegate?.sessionManager(manager: self, didInitiate: newSession)
            }

        } catch {
            delegate?.sessionManager(manager: self, didFailWith: spotifyError)
        }
    }

    func initiateClientOnlyRedirectAppStore(with authorizationURL: URL) {
        guard isSpotifyAppInstalled else {
            let storeVC = SKStoreProductViewController()
            storeVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: Constant.Client.appStoreIdentifier]) { _, error in
                guard error == nil else {
                    return
                }
                self.presentViewController(storeVC)
            }
            return
        }

        UIApplication.shared.open(authorizationURL, options: [:]) { [weak self] success in
            guard let self else {
                return
            }
            if !success {
                self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            }
        }
    }

    /// Initiates client authorization session
    /// - Parameter authorizationURL: The authorization URL with spotify-action:// scheme to open in the Spotify app.
    /// - Parameter useWebSessionAsFallback: If `true`, falls back to web-based authentication via `ASWebAuthenticationSession` when opening the Spotify app fails. If `false`, reports an error to the delegate instead.
    ///
    /// When the Spotify app successfully opens and the user authorizes, the app will callback via the configured redirect URL scheme,
    /// which should be handled by the app delegate and passed to `openURL(_:)`.
    func initiateClientSession(with authorizationURL: URL, useWebSessionAsFallback: Bool) {
        UIApplication.shared.open(authorizationURL, options: [:]) { [weak self] success in
            guard let self else { return }

            if !success {
                // Failed to open Spotify app
                if useWebSessionAsFallback {
                    // Fall back to web-based authentication
                    self.initiateWebSession(with: authorizationURL)
                } else {
                    // No fallback - report failure
                    self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
                }
            }
            // If success is true, wait for app to callback via URL scheme
        }
    }

    /// Initiates a web-based authorization session using `ASWebAuthenticationSession`.
    /// - Parameter authorizationURL: The authorization URL with spotify-action:// scheme, which will be converted to an https:// URL for web authentication.
    ///
    /// This method converts the app-based authorization URL (spotify-action://) to a web-based URL (https://accounts.spotify.com),
    /// then presents an in-app browser for the user to authenticate. On iOS 17.4+, it supports both HTTPS and custom scheme callbacks.
    /// On earlier versions, only custom scheme callbacks are supported.
    ///
    /// The authentication session is stored in `authenticationSession` and automatically cleaned up upon completion.
    /// Results are delivered to the delegate via `sessionManager(manager:didInitiate:)` or `sessionManager(manager:didFailWith:)`.
    func initiateWebSession(with authorizationURL: URL) {
        // Convert spotify-action:// URL back to https:// for web authentication
        let webAuthURLString = authorizationURL.absoluteString
            .replacingOccurrences(
                of: Constant.Client.actionScheme,
                with: Constant.OAuth.serviceOriginURLString
            )

        guard let webAuthURL = URL(string: webAuthURLString) else {
            delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
            return
        }

        let completionHandler: ASWebAuthenticationSession.CompletionHandler = { [weak self] callbackURL, error in
            guard let self else { return }

            // Clean up the session reference when done
            defer {
                self.authenticationSession = nil
            }

            if let error {
                // Check if user cancelled the authentication
                if let authError = error as? ASWebAuthenticationSessionError,
                   authError.code == .canceledLogin {
                    self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationCancelled)
                } else {
                    // Other errors are treated as authorization failures
                    self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
                }
                return
            }

            guard let callbackURL else {
                self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
                return
            }

            // Process the callback URL through the standard flow
            _ = self.authenticateWithURL(callbackURL)
        }

        // Create authentication session with iOS version-specific API
        if #available(iOS 17.4, *) {
            // iOS 17.4+ supports HTTPS callbacks
            let redirectURL = configuration.redirectURL

            let callback: ASWebAuthenticationSession.Callback
            if redirectURL.scheme == "https" {
                guard let redirectURLHost = redirectURL.host else {
                    self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
                    return
                }
                // Use HTTPS callback for https:// redirect URLs
                callback = .https(host: redirectURLHost, path: redirectURL.path)
            } else {
                // Use custom scheme callback for non-HTTPS redirect URLs
                guard let redirectURLScheme = redirectURL.scheme else {
                    self.delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
                    return
                }
                callback = .customScheme(redirectURLScheme)
            }

            authenticationSession = ASWebAuthenticationSession(
                url: webAuthURL,
                callback: callback,
                completionHandler: completionHandler
            )
        } else {
            // Pre-iOS 17.4: Use custom scheme callback
            guard let scheme = configuration.redirectURL.scheme else {
                delegate?.sessionManager(manager: self, didFailWith: SpotifyError.authorizationFailed)
                return
            }
            authenticationSession = ASWebAuthenticationSession(
                url: webAuthURL,
                callbackURLScheme: scheme,
                completionHandler: completionHandler
            )
        }

        authenticationSession?.presentationContextProvider = self
        authenticationSession?.prefersEphemeralWebBrowserSession = false

        DispatchQueue.main.async {
            self.authenticationSession?.start()
        }
    }

    func authorizationURL(with scopes: [Scope], campaign: String? = nil) -> URL? {
        var components = URLComponents(string: Constant.Client.actionScheme + Constant.OAuth.authorizeEndpoint)
        let frameworkBundle = Bundle(for: SessionManager.self)
        let frameworkBundleID = frameworkBundle.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String
        let frameworkVersion = frameworkBundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String

        var queryItems: [URLQueryItem] = [
            URLQueryItem(
                name: Constant.OAuth.clientIDParameterName,
                value: configuration.clientID
            ),
            URLQueryItem(
                name: Constant.OAuth.redirectURIParameterName,
                value: configuration.redirectURL.absoluteString
            ),
            URLQueryItem(
                name: Constant.OAuth.scopeParameterName,
                value: SessionManager.string(from: scopes)
            ),
            URLQueryItem(
                name: Constant.OAuth.responseTypeParameterName,
                value: Constant.OAuth.codeResponseTypeParameterValue
            ),
            URLQueryItem(
                name: Constant.Query.utmSourceParameterName,
                value: Bundle.main.bundleIdentifier
            ),
            URLQueryItem(
                name: Constant.Query.utmMediumParameterName,
                value: frameworkBundleID
            ),
            URLQueryItem(
                name: Constant.Query.utmContentParameterName,
                value: frameworkVersion
            ),
            URLQueryItem(
                name: Constant.Query.utmCampaignParameterName,
                value: campaign
            ),
            URLQueryItem(
                name: Constant.Query.noSignUpParameterName,
                value: Constant.Query.noSignUpParameterValue
            ),
            URLQueryItem(
                name: Constant.Query.noLinksParameterName,
                value: Constant.Query.noLinksParameterValue
            ),
        ]

        // Add PKCE parameters only if not using token swap
        if configuration.tokenSwapURL == nil, let pkce = currentPKCEPair {
            queryItems.append(contentsOf: [
                URLQueryItem(
                    name: Constant.OAuth.codeChallengeParameterName,
                    value: pkce.codeChallenge
                ),
                URLQueryItem(
                    name: Constant.OAuth.codeChallengeMethodParameterName,
                    value: Constant.OAuth.s256CodeChallengeMethodParameterValue
                ),
            ])
        }

        components?.queryItems = queryItems

        return components?.url
    }

    func authorizationCode(from url: URL) -> String? {
        // Extract code from query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return nil
        }

        return items.first { $0.name == Constant.OAuth.codeParameterName }?.value
    }

    static func string(from scopes: [Scope]) -> String {
        let uniqueScopes = Set(scopes.map(\.name))
        return uniqueScopes.joined(separator: Constant.OAuth.scopeParameterSeparator)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension SessionManager: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return keyWindow ?? ASPresentationAnchor()
    }
}

// MARK: - Private

extension SessionManager {
    private var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func presentViewController(_ viewController: UIViewController) {
        DispatchQueue.main.async {
            self.keyWindow?.rootViewController?.present(viewController, animated: true)
        }
    }

    private func tokenRefreshURL() -> URL? {
        if let customURL = configuration.tokenRefreshURL {
            return customURL
        }

        var components = URLComponents(string: Constant.OAuth.serviceOriginURLString)
        components?.path = Constant.OAuth.tokenEndpoint
        return components?.url
    }
}
