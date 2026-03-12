@testable import SpotifyLogin

import XCTest

final class UtilsTests: XCTestCase {

    // MARK: - URL Form Encoding Extension Tests

    func testFormURLEncodedData() {
        // Given
        let parameters: [String: String] = [
            "client_id": "test_client",
            "grant_type": "authorization_code",
            "code": "auth_code_123",
        ]

        // When
        let data = parameters.formURLEncodedData()

        // Then
        XCTAssertNotNil(data)
        let string = String(data: data!, encoding: .utf8)!
        XCTAssertTrue(string.contains("client_id=test_client"))
        XCTAssertTrue(string.contains("grant_type=authorization_code"))
        XCTAssertTrue(string.contains("code=auth_code_123"))
    }

    func testFormURLEncodedDataWithSpecialCharacters() {
        // Given
        let parameters: [String: String] = [
            "redirect_uri": "https://example.com/callback",
            "state": "test state with spaces",
        ]

        // When
        let data = parameters.formURLEncodedData()

        // Then
        XCTAssertNotNil(data)
        let string = String(data: data!, encoding: .utf8)!
        // URL encoding should handle special characters
        XCTAssertTrue(string.contains("redirect_uri="))
        XCTAssertTrue(string.contains("state="))
    }

    func testFormURLEncodedDataEmptyDictionary() {
        // Given
        let parameters: [String: String] = [:]

        // When
        let data = parameters.formURLEncodedData()

        // Then
        XCTAssertNotNil(data)
        let string = String(data: data!, encoding: .utf8)
        XCTAssertEqual(string, "")
    }

    // MARK: - Base64URL Encoding Extension

    func testBase64URLEncoding() {
        // Given
        // Test that Base64URL encoding works correctly
        let testData = "Hello, World!".data(using: .utf8)!

        // When
        let base64URL = testData.base64URLEncodedString()

        // Then
        // Standard base64: "SGVsbG8sIFdvcmxkIQ=="
        // Base64URL should replace + with -, / with _, and remove padding
        XCTAssertFalse(base64URL.contains("+"))
        XCTAssertFalse(base64URL.contains("/"))
        XCTAssertFalse(base64URL.contains("="))

        // Should contain URL-safe characters
        XCTAssertEqual("SGVsbG8sIFdvcmxkIQ", base64URL)
    }

    func testBase64URLEncodingWithSpecialCharacters() {
        // Given
        // Create data that would produce + and / in standard base64
        let testBytes: [UInt8] = [0xFB, 0xFF, 0xBF, 0x3E, 0x3F]
        let testData = Data(testBytes)

        // When
        let base64URL = testData.base64URLEncodedString()

        // Then
        // Verify URL-safe encoding
        XCTAssertFalse(base64URL.contains("+"))
        XCTAssertFalse(base64URL.contains("/"))
        XCTAssertFalse(base64URL.contains("="))

        // Standard base64 would be: "+/+/Pj8="
        // Base64URL should be: "-_-_Pj8"
        XCTAssertEqual("-_-_Pj8", base64URL)
    }
}
