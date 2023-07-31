#import <Foundation/Foundation.h>

/// `SPTScope` represents the OAuth scopes that declare how your app wants to access a user's account.
/// See https://developer.spotify.com/web-api/using-scopes/ for more information.
typedef NS_OPTIONS(NSUInteger, SPTScope) {
    // Read access to user's private playlists.
    SPTScopePlaylistReadPrivate = 1 << 0,

    // Include collaborative playlists when requesting a user's playlists.
    SPTScopePlaylistReadCollaborative = 1 << 1,

    // Write access to a user's public playlists.
    SPTScopePlaylistModifyPublic = 1 << 2,

    // Write access to a user's private playlists.
    SPTScopePlaylistModifyPrivate = 1 << 3,

    // Read access to the list of artists and other users that the user follows.
    SPTScopeUserFollowRead = 1 << 4,

    // Write/delete access to the list of artists and other users that the user follows.
    SPTScopeUserFollowModify = 1 << 5,

    // Read access to a user's "Your Music" library.
    SPTScopeUserLibraryRead = 1 << 6,

    // Write/delete access to a user's "Your Music" library.
    SPTScopeUserLibraryModify = 1 << 7,

    // Read access to the user's birthdate.
    SPTScopeUserReadBirthDate = 1 << 8,

    // Read access to user’s email address.
    SPTScopeUserReadEmail = 1 << 9,

    // Read access to user’s subscription details (type of user account).
    SPTScopeUserReadPrivate = 1 << 10,

    // Read access to a user's top artists and tracks.
    SPTScopeUserTopRead = 1 << 11,

    // Upload user generated content images.
    SPTScopeUgcImageUpload = 1 << 12,

    // Control playback of a Spotify track.
    SPTScopeStreaming = 1 << 13,

    // Read access to a user’s player state.
    SPTScopeUserReadPlaybackState = 1 << 14,

    // Write access to a user’s playback state.
    SPTScopeUserModifyPlaybackState = 1 << 15,

    // Read access to a user’s currently playing track.
    SPTScopeUserReadCurrentlyPlaying = 1 << 16,

    // Read access to a user’s recently played tracks.
    SPTScopeUserReadRecentlyPlayed = 1 << 17,

    // Indicate that the application intends to use OIDC to verify the user's identity
    SPTScopeOpenid = 1 << 18
} NS_SWIFT_NAME(Scope);
