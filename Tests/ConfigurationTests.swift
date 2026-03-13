@testable import SpotifyLogin

import XCTest

final class ConfigurationTests: XCTestCase {
    private let validClientID = "5fe01282e44241328a84e7c5cc169165"
    private let validRedirectURL = URL(string: "https://example.com")!

    func testInvalidConfigurationValidation() {
        // Given
        let invalidClientID = "The last Metroid is in captivity. The galaxy is at peace..."
        let invalidRedirectURL = URL(string: "test")!

        // Then
        XCTAssertFalse(Configuration.isValid(clientID: invalidClientID))
        XCTAssertFalse(Configuration.isValid(redirectURL: invalidRedirectURL))
    }

    func testEncodeWithCoder() {
        // Given
        let coder = FakeCoder()
        let config = Configuration(clientID: validClientID, redirectURL: validRedirectURL)

        // When
        config.encode(with: coder)

        // Then
        XCTAssertEqual(coder.objects[Configuration.ArchiveKeys.clientID] as? NSString, validClientID as NSString)
        XCTAssertEqual(
            coder.objects[Configuration.ArchiveKeys.redirectURL] as? NSURL,
            validRedirectURL as NSURL
        )
    }

    func testInitWithCoderRoundTrip() throws {
        // Given
        let original = Configuration(clientID: validClientID, redirectURL: validRedirectURL)

        // When
        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let decoded = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: Configuration.self, from: data))

        // Then
        XCTAssertEqual(decoded.clientID, validClientID)
        XCTAssertEqual(decoded.redirectURL, validRedirectURL)
    }

    func testSupportsSecureCoding() {
        XCTAssertTrue(Configuration.supportsSecureCoding)
    }
}
