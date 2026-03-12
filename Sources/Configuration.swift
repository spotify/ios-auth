import Foundation

/// A configuration class, holding the credentials provided for your app on the Spotify Developer website.
/// See https://developer.spotify.com/my-applications/
@objc(SPTConfiguration)
@objcMembers
public final class Configuration: NSObject {
    /// Your app's Client ID from developer.spotify.com
    public let clientID: String

    /// Your redirect URL. This is how the Spotify app will open your application after user authorization.
    public let redirectURL: URL

    /// The URL to use for attempting to swap an authorization code for an access token.
    public var tokenSwapURL: URL?

    /// The URL to use for attempting to renew an access token with a refresh token.
    public var tokenRefreshURL: URL?

    /// Optional URI to begin playing after a successful authentication.
    public var playURI: String?

    /// Initializer for `Configuration`
    /// - Parameter clientID: Your client ID obtained from developer.spotify.com
    /// - Parameter redirectURL: Your redirect URL for Spotify to open your app again after authorization
    public init(
        clientID: String,
        redirectURL: URL
    ) {
        assert(Configuration.isValid(clientID: clientID))
        assert(Configuration.isValid(redirectURL: redirectURL))

        self.clientID = clientID
        self.redirectURL = redirectURL
    }

    // MARK: - Private helper methods

    static func isValid(clientID: String) -> Bool {
        let regex = "^[0-9a-z]{32}$"
        return clientID.range(of: regex, options: [.regularExpression]) != nil
    }

    static func isValid(redirectURL: URL) -> Bool {
        return redirectURL.scheme != nil
    }
}

// MARK: - NSSecureCoding

extension Configuration: NSSecureCoding {
    enum ArchiveKeys {
        static let clientID = "SPTConfigurationClientIDKey"
        static let redirectURL = "SPTConfigurationRedirectURLKey"
    }

    public static var supportsSecureCoding: Bool { true }

    public convenience init?(coder: NSCoder) {
        guard let clientID = coder.decodeObject(of: NSString.self, forKey: ArchiveKeys.clientID) as String? else {
            return nil
        }
        guard let redirectURL = coder.decodeObject(of: NSURL.self, forKey: ArchiveKeys.redirectURL) as URL? else {
            return nil
        }

        guard Configuration.isValid(clientID: clientID),
              Configuration.isValid(redirectURL: redirectURL) else {
            return nil
        }

        self.init(clientID: clientID, redirectURL: redirectURL)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(self.clientID as NSString, forKey: ArchiveKeys.clientID)
        coder.encode(self.redirectURL as NSURL, forKey: ArchiveKeys.redirectURL)
    }
}
