@testable import SpotifyLogin

import XCTest

final class SessionTests: XCTestCase {
    private let token = "token"
    private let refreshToken = "refresh"

    // Use the internal ArchiveKeys from Session

    func testExpiredSession() {
        // Given
        let expiredDate = Date(timeIntervalSinceNow: -1.0)

        // When
        let session = Session(
            accessToken: token,
            refreshToken: refreshToken,
            expirationDate: expiredDate,
            scopes: []
        )

        // Then
        XCTAssertTrue(session.isExpired)
    }

    func testValidSession() {
        // Given
        let futureDate = Date(timeIntervalSinceNow: 10.0)

        // When
        let session = Session(
            accessToken: token,
            refreshToken: refreshToken,
            expirationDate: futureDate,
            scopes: []
        )

        // Then
        XCTAssertFalse(session.isExpired)
    }

    func testEncodeWithCoder() {
        // Given
        let coder = FakeCoder()
        let futureDate = Date(timeIntervalSinceNow: 10.0)
        let scopes: [Scope] = [.playlistReadPrivate, .userReadEmail]
        let expectedMask = Scope.playlistReadPrivate.bitmask | Scope.userReadEmail.bitmask
        let session = Session(
            accessToken: token,
            refreshToken: refreshToken,
            expirationDate: futureDate,
            scopes: scopes
        )

        // When
        session.encode(with: coder)

        // Then
        XCTAssertEqual(coder.objects[Session.ArchiveKeys.accessToken] as? NSString, token as NSString)
        XCTAssertEqual(coder.objects[Session.ArchiveKeys.refreshToken] as? NSString, refreshToken as NSString)
        XCTAssertEqual(coder.objects[Session.ArchiveKeys.expirationDate] as? NSDate, futureDate as NSDate)
        XCTAssertEqual((coder.objects[Session.ArchiveKeys.scope] as? NSNumber)?.uintValue, UInt(expectedMask))
    }

    func testInitWithCoderRoundTrip() throws {
        // Given
        let futureDate = Date(timeIntervalSinceNow: 10.0)
        let scopes: [Scope] = [.playlistReadPrivate, .userReadEmail]
        let original = Session(
            accessToken: token,
            refreshToken: refreshToken,
            expirationDate: futureDate,
            scopes: scopes
        )

        // When
        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let decoded = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: Session.self, from: data))

        // Then
        XCTAssertEqual(decoded.accessToken, token)
        XCTAssertEqual(decoded.refreshToken, refreshToken)
        XCTAssertEqual(decoded.expirationDate, futureDate)
        XCTAssertEqual(Set(decoded.scopes), Set(scopes))
    }

    func testSupportsSecureCoding() {
        XCTAssertTrue(Session.supportsSecureCoding)
    }
}
