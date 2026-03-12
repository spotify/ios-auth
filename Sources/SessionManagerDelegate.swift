import Foundation

@objc(SPTSessionManagerDelegate)
public protocol SessionManagerDelegate {
    /// Called when a session has been initiated successfully.
    ///
    /// - Parameter manager: The `SessionManager` that initiated the session.
    /// - Parameter session: The initiated `Session` object.
    func sessionManager(manager: SessionManager, didInitiate session: Session)

    /// Called when the manager failed to initiate or renew a session.
    ///
    /// - Parameter manager: The `SessionManager` instance.
    /// - Parameter error: The `Error` that occured.
    func sessionManager(manager: SessionManager, didFailWith error: Error)

    /// Called when the manager has renewed a session.
    ///
    /// - Parameter manager: The `SessionManager` instance.
    /// - Parameter session: The renewed `Session` object.
    @objc optional
    func sessionManager(manager: SessionManager, didRenew session: Session)

    /// Called when the `SessionManager` has obtained an authorization code,
    /// and is about to swap it for an access token. If you wish to handle this
    /// yourself, return `false` and use the provided authorization code.
    ///
    /// - Parameter manager:  The `SessionManager` instance.
    /// - Parameter code: An OAuth authorization code.
    /// - Returns: `false` to request the access token yourself; `true` to let `SessionManager` handle it.
    @objc optional
    func sessionManager(manager: SessionManager, shouldRequestAccessTokenWith code: String) -> Bool
}
