import Foundation

@objc(SPTAuthorizationFlow)
public enum AuthorizationFlow: Int, CaseIterable {
    /// Recommended.
    /// Authorize using the Spotify app, and fall back to a Web Session authentication using ASWebAuthentication if Spotify is not installed.
    case `default` = 0
    /// Authorize using only the Spotify client, but redirect to AppStore if Spotify is not installed.
    case clientOnlyRedirectAppStore = 1
    /// Authorize using only the Spotify client, and fail if Spotify is not installed.
    case clientOnlyFailsIfNotInstalled = 2
    /// Use this option if you have reached the limit of `LSApplicationQueriesSchemes` in your Info.plist
    /// Attempt to open Spotify app directly without using `canOpenURL`.
    /// Falls back to ASWebAuthentication if opening fails.
    case spotifySchemeNotRegistered = 3
}
