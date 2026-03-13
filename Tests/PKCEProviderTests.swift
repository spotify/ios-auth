import CryptoKit
@testable import SpotifyLogin
import XCTest

final class PKCEProviderTests: XCTestCase {

    // MARK: - PKCEPair Tests

    func testGeneratePKCEPair() throws {
        // When
        let pair = try PKCEProvider.generatePKCEPair()

        // Then
        XCTAssertEqual(43, pair.codeVerifier.count)
        XCTAssertEqual(43, pair.codeChallenge.count)
        XCTAssertNotEqual(pair.codeVerifier, pair.codeChallenge)
    }

    func testGeneratePKCEPairGeneratesNewValues() throws {
        // Given
        let firstPair = try PKCEProvider.generatePKCEPair()

        // When
        let secondPair = try PKCEProvider.generatePKCEPair()

        // Then
        XCTAssertNotEqual(firstPair.codeVerifier, secondPair.codeVerifier)
        XCTAssertNotEqual(firstPair.codeChallenge, secondPair.codeChallenge)
    }

    // MARK: - Code Verifier Tests

    func testValidChars() throws {
        // When
        let pair = try PKCEProvider.generatePKCEPair()

        // Then
        XCTAssertEqual(43, pair.codeVerifier.count, "Code verifier should always be 43 characters (RFC 7636 recommendation)")

        // Verify it matches the regex pattern for valid PKCE code verifiers
        // RFC 7636 allows: [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
        // Our Base64URL encoding produces: [A-Z] / [a-z] / [0-9] / "-" / "_"
        let verifierRegEx = "^[A-Za-z0-9\\-_]{43}$"
        let range = pair.codeVerifier.range(of: verifierRegEx, options: .regularExpression)
        XCTAssertNotNil(range, "Code verifier should only contain Base64URL characters [A-Za-z0-9-_]")
    }

    func testCodeVerifierIsURLSafe() throws {
        // When
        let pair = try PKCEProvider.generatePKCEPair()

        // Then
        // Ensure no URL-unsafe characters
        XCTAssertFalse(pair.codeVerifier.contains("+"), "Verifier should not contain '+'")
        XCTAssertFalse(pair.codeVerifier.contains("/"), "Verifier should not contain '/'")
        XCTAssertFalse(pair.codeVerifier.contains("="), "Verifier should not contain padding '='")

        // Ensure it's valid for use in URLs
        let urlString = "https://example.com?code_verifier=\(pair.codeVerifier)"
        XCTAssertNotNil(URL(string: urlString), "Verifier should be URL-safe")
    }

    // MARK: - S256 Code Challenge Tests

    func testCreatePKCES256CodeChallengePythonOracle() {
        /*
         Python oracle:

         import base64, hashlib, re
         s256 = hashlib.sha256()
         s256.update(b'WH.niWrr1n5Ao~um9y9CH9ojrxNx8fhWnDfpKnl~_A~6uvxRbOWzt3gaFunmo0G1')
         b64 = base64.urlsafe_b64encode(s256.digest())
         re.sub(r'=+$', '', b64.decode('ascii'))  # 'uqEUPTS-XRI_F7bcKMr9qNReV6sStTWNp4jFoSPs8mo'
         */

        // Given
        let verifier = "WH.niWrr1n5Ao~um9y9CH9ojrxNx8fhWnDfpKnl~_A~6uvxRbOWzt3gaFunmo0G1"
        let expectedChallenge = "uqEUPTS-XRI_F7bcKMr9qNReV6sStTWNp4jFoSPs8mo"

        // When
        let actualChallenge = PKCEProvider.generateS256CodeChallenge(from: verifier)

        // Then
        XCTAssertEqual(expectedChallenge, actualChallenge)
    }

    // https://tools.ietf.org/html/rfc7636#appendix-B
    func testCreatePKCES256CodeChallengeRFC7636Example() {
        // Given
        let exampleVerifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let exampleCodeChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        // When
        // Test production code with RFC 7636 official test vector
        let actualChallenge = PKCEProvider.generateS256CodeChallenge(from: exampleVerifier)

        // Then
        XCTAssertEqual(exampleCodeChallenge, actualChallenge)
    }

    // MARK: - Error Handling Tests

    func testS256ChallengeIsDifferentFromVerifier() throws {
        // When
        // In S256 mode, challenge should NOT equal verifier (it's a hash)
        let pair = try PKCEProvider.generatePKCEPair()

        // Then
        XCTAssertNotEqual(
            pair.codeVerifier,
            pair.codeChallenge,
            "S256 challenge should be different from verifier (it's a SHA256 hash)"
        )
    }
}
