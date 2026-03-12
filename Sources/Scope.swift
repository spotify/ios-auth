import Foundation

/// `Scope` represents the OAuth scopes that declare how your app wants to access a user's account.
/// See https://developer.spotify.com/web-api/using-scopes/ for more information.
@objc(SPTScope)
public enum Scope: Int, CaseIterable {
    case playlistReadPrivate = 0
    case playlistReadCollaborative = 1
    case playlistModifyPublic = 2
    case playlistModifyPrivate = 3
    case userFollowRead = 4
    case userFollowModify = 5
    case userLibraryRead = 6
    case userLibraryModify = 7
    case userReadBirthDate = 8
    case userReadEmail = 9
    case userReadPrivate = 10
    case userTopRead = 11
    case ugcImageUpload = 12
    case streaming = 13
    case appRemoteControl = 14
    case userReadPlaybackState = 15
    case userModifyPlaybackState = 16
    case userReadCurrentlyPlaying = 17
    case userReadRecentlyPlayed = 18
    case openid = 19

    public var name: String {
        switch self {
        case .playlistReadPrivate: return "playlist-read-private"
        case .playlistReadCollaborative: return "playlist-read-collaborative"
        case .playlistModifyPublic: return "playlist-modify-public"
        case .playlistModifyPrivate: return "playlist-modify-private"
        case .userFollowRead: return "user-follow-read"
        case .userFollowModify: return "user-follow-modify"
        case .userLibraryRead: return "user-library-read"
        case .userLibraryModify: return "user-library-modify"
        case .userReadBirthDate: return "user-read-birthdate"
        case .userReadEmail: return "user-read-email"
        case .userReadPrivate: return "user-read-private"
        case .userTopRead: return "user-top-read"
        case .ugcImageUpload: return "ugc-image-upload"
        case .streaming: return "streaming"
        case .appRemoteControl: return "app-remote-control"
        case .userReadPlaybackState: return "user-read-playback-state"
        case .userModifyPlaybackState: return "user-modify-playback-state"
        case .userReadCurrentlyPlaying: return "user-read-currently-playing"
        case .userReadRecentlyPlayed: return "user-read-recently-played"
        case .openid: return "openid"
        }
    }

    var bitmask: Int {
        return 1 << self.rawValue
    }

    /// Parse scopes from a space-separated string
    /// - Parameter scopeString: A space-separated string of scope names (e.g., "playlist-read-private user-read-email")
    /// - Returns: An array of Scope values
    static func scopes(from scopeString: String) -> [Scope] {
        let scopeNames = Set(scopeString.split(separator: " ").map(String.init))
        return allCases.filter { scopeNames.contains($0.name) }
    }
}
