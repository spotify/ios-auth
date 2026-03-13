@testable import SpotifyLogin

import XCTest

final class ScopeTests: XCTestCase {

    // MARK: - Scopes From String Tests

    func testScopesFromStringSingleScope() {
        // Given
        let scopeString = "playlist-read-private"

        // When
        let scopes = Scope.scopes(from: scopeString)

        // Then
        XCTAssertEqual(scopes.count, 1)
        XCTAssertEqual(scopes.first, .playlistReadPrivate)
    }

    func testScopesFromStringMultipleScopes() {
        // Given
        let scopeString = "playlist-read-private user-read-email streaming"

        // When
        let scopes = Scope.scopes(from: scopeString)

        // Then
        XCTAssertEqual(scopes.count, 3)
        XCTAssertTrue(scopes.contains(.playlistReadPrivate))
        XCTAssertTrue(scopes.contains(.userReadEmail))
        XCTAssertTrue(scopes.contains(.streaming))
    }

    func testScopesFromStringIgnoresUnknownScopes() {
        // Given
        let scopeString = "playlist-read-private unknown-scope-123 user-read-email another-unknown"

        // When
        let scopes = Scope.scopes(from: scopeString)

        // Then
        XCTAssertEqual(scopes.count, 2)
        XCTAssertTrue(scopes.contains(.playlistReadPrivate))
        XCTAssertTrue(scopes.contains(.userReadEmail))
    }

    func testScopesFromStringEmptyString() {
        // Given
        let scopeString = ""

        // When
        let scopes = Scope.scopes(from: scopeString)

        // Then
        XCTAssertEqual(scopes.count, 0)
    }

    func testScopesFromStringWhitespaceOnly() {
        // Given
        let scopeString = "   "

        // When
        let scopes = Scope.scopes(from: scopeString)

        // Then
        XCTAssertEqual(scopes.count, 0)
    }
}
