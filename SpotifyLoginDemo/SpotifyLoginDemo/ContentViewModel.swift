import SwiftUI
import SpotifyLogin

final class ContentViewModel: ObservableObject {
    private let clientURLScheme = "spotify:"

    enum State: Equatable {
        case idle
        case success(String)
        case failure(String)
    }

    @Published private(set) var state: State = .idle
    private let spotifyClientID = "6ca3f1f77b194899ae4c6674843e2510"
    private let spotifyRedirectURL = "spotify-login-sdk-demo-app://spotify-login-callback"
    private lazy var sessionManager: SessionManager = {
        let configuration = Configuration(clientID: spotifyClientID, redirectURLString: spotifyRedirectURL)
        return SessionManager(configuration: configuration)
    }()

    init() {
        sessionManager.delegate = self
    }
}

extension ContentViewModel {
    func startAuthorizationCodeProcess() {
        let scopes: Scope = .playlistReadPrivate
        sessionManager.startAuthorizationCodeProcess(with: scopes)
    }

    func open(url: URL) {
        let result = sessionManager.openURL(url)
        if !result {
            state = .failure("Authorization Failed")
        }
    }

    func setStateIdle() {
        state = .idle
    }
}

extension ContentViewModel: SessionManagerDelegate {
    func sessionManager(manager: SessionManager, didFailWith error: Error) {
        state = .failure("Authorization Failed")
    }

    func sessionManager(manager: SessionManager, shouldRequestAccessTokenWith code: String) {
        state = .success("Authorization Succeeded")
    }
}
