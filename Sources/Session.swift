import Foundation

@objc(SPTSession)
@objcMembers
public final class Session: NSObject {

    /// The access token of the authenticated user.
    public let accessToken: String

    /// The refresh token.
    public let refreshToken: String

    /// The expiration date of the access token.
    public let expirationDate: Date

    /// The granted scopes as string-backed `Scope` values.
    public let scopes: [Scope]

    /// Check whether the session has expired.
    public var isExpired: Bool { Date() >= expirationDate }

    enum ArchiveKeys {
        static let accessToken = "SPTSessionAccessTokenKey"
        static let refreshToken = "SPTSessionRefreshTokenKey"
        static let expirationDate = "SPTSessionExpirationDateKey"
        static let scope = "SPTSessionScopeKey"
    }

    public init(accessToken: String, refreshToken: String, expirationDate: Date, scopes: [Scope]) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
        self.scopes = scopes
    }
}

// MARK: - NSSecureCoding

extension Session: NSSecureCoding {

    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(self.accessToken as NSString, forKey: ArchiveKeys.accessToken)
        coder.encode(self.refreshToken as NSString, forKey: ArchiveKeys.refreshToken)
        coder.encode(self.expirationDate as NSDate, forKey: ArchiveKeys.expirationDate)

        let scopeMaskInt: Int = scopes.reduce(0) { $0 | $1.bitmask }
        // We're packing the scopes in a single int instead of just storing the array
        // to mantain compatibility with objective-c version of the SDK (iOSAuthSDK)
        coder.encode(NSNumber(value: UInt(scopeMaskInt)), forKey: ArchiveKeys.scope)
    }

    public convenience init?(coder: NSCoder) {
        guard
            let accessToken = coder.decodeObject(of: NSString.self, forKey: ArchiveKeys.accessToken) as String?,
            let refreshToken = coder.decodeObject(of: NSString.self, forKey: ArchiveKeys.refreshToken) as String?,
            let expirationDate = coder.decodeObject(of: NSDate.self, forKey: ArchiveKeys.expirationDate) as Date?,
            let scopeNumber = coder.decodeObject(of: NSNumber.self, forKey: ArchiveKeys.scope)
        else {
            return nil
        }

        let mask: UInt = scopeNumber.uintValue
        var decodedScopes: [Scope] = []
        var raw = 0
        while let s = Scope(rawValue: raw) {
            if (mask & UInt(s.bitmask)) != 0 {
                decodedScopes.append(s)
            }
            raw += 1
        }

        self.init(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expirationDate: expirationDate,
            scopes: decodedScopes
        )
    }
}
