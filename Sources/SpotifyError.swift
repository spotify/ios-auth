import Foundation

/// Spotify error codes
public enum SpotifyError: Int, Error {
    /// Unknown error code
    case unknown = 0
    /// Authorization failed
    case authorizationFailed = 1
    /// User cancelled the authorization process
    case authorizationCancelled = 2
    /// User denied the authorization process
    case accessDenied = 3
    /// Renew session failed
    case renewSessionFailed = 4
}

extension SpotifyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error occurred"
        case .authorizationFailed:
            return "Authorization failed"
        case .authorizationCancelled:
            return "User cancelled the authorization"
        case .accessDenied:
            return "User denied the access"
        case .renewSessionFailed:
            return "Failed to renew session"
        }
    }
}

extension SpotifyError: CustomNSError {
    public static var errorDomain: String {
        return "com.spotify.sdk.SpotifyLogin"
    }

    public var errorCode: Int {
        return self.rawValue
    }

    public var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: errorDescription ?? ""]
    }
}
