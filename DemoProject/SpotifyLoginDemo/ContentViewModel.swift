import SpotifyLogin
import SwiftUI

final class ContentViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case success(String)
        case failure(String)
    }

    @Published private(set) var state: State = .idle

    // Add here your clientID and redirect URI
    private let spotifyClientID = <#ClientID#>
    private let spotifyRedirectURL = URL(string: <#redirectURI#>)!

    private lazy var sessionManager: SessionManager = {
        let configuration = Configuration(clientID: spotifyClientID, redirectURL: spotifyRedirectURL)
        return SessionManager(configuration: configuration, delegate: self)
    }()
}

extension ContentViewModel {
    func startAuthorizationCodeProcess() {
        let scopes: [Scope] = [.playlistReadPrivate]
        sessionManager.initiateSession(with: scopes)
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
    func sessionManager(manager: SessionManager, didInitiate session: Session) {
        DispatchQueue.main.async {
            self.state = .success("Authorization Succeeded\nAccess Token: \(session.accessToken)")
        }
    }

    func sessionManager(manager: SessionManager, didFailWith error: Error) {
        DispatchQueue.main.async {
            self.state = .failure("Authorization Failed: \(error.localizedDescription)")
        }
    }
}
