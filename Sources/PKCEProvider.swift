import CryptoKit
import Foundation

/// A PKCE (Proof Key for Code Exchange) pair containing a code verifier and its corresponding code challenge.
/// See https://tools.ietf.org/html/rfc7636 for more information.
struct PKCEPair {
    /// The PKCE code verifier (always 43 characters as recommended by RFC 7636).
    let codeVerifier: String

    /// The PKCE code challenge (SHA256 hash of verifier, Base64URL encoded).
    let codeChallenge: String
}

/// Errors that can occur during PKCE operations
enum PKCEError: Error {
    case randomGenerationFailed
}

/// Provides PKCE (Proof Key for Code Exchange) generation functionality per RFC 7636.
///
/// The code verifier is always 43 characters (providing 258 bits of entropy) as recommended by RFC 7636.
/// The S256 challenge method is always used (SHA256 hash of the verifier, Base64URL encoded).
enum PKCEProvider {
    /// Generate a new PKCE pair (code verifier and code challenge).
    ///
    /// The code verifier is generated from 32 random bytes (256 bits of entropy) and Base64URL encoded to 43 characters.
    /// The code challenge is the SHA256 hash of the verifier, Base64URL encoded.
    ///
    /// - Returns: A PKCEPair containing the code verifier and code challenge
    /// - Throws: PKCEError.randomGenerationFailed if secure random generation fails
    static func generatePKCEPair() throws -> PKCEPair {
        let byteLength = 32
        var randomBytes = [UInt8](repeating: 0, count: byteLength)

        guard SecRandomCopyBytes(kSecRandomDefault, byteLength, &randomBytes) == errSecSuccess else {
            throw PKCEError.randomGenerationFailed
        }

        // Base64URL encode the random bytes (32 bytes → 43 characters)
        let codeVerifier = Data(randomBytes).base64URLEncodedString()
        assert(codeVerifier.count == 43, "32 bytes should always encode to 43 Base64URL characters")

        // Generate S256 code challenge
        let codeChallenge = generateS256CodeChallenge(from: codeVerifier)

        return PKCEPair(codeVerifier: codeVerifier, codeChallenge: codeChallenge)
    }

    /// Generate an S256 code challenge from a given code verifier.
    ///
    /// This method is primarily useful for testing with known verifiers (e.g., RFC 7636 test vectors).
    /// For normal use, call `generatePKCEPair()` instead.
    ///
    /// - Parameter codeVerifier: The code verifier string (should be 43 characters)
    /// - Returns: The S256 code challenge (SHA256 hash of verifier, Base64URL encoded)
    static func generateS256CodeChallenge(from codeVerifier: String) -> String {
        // SHA256 hash the code verifier
        let hash = SHA256.hash(data: Data(codeVerifier.utf8))

        // Base64URL encode the hash (32 bytes → 43 characters)
        let codeChallenge = Data(hash).base64URLEncodedString()
        assert(codeChallenge.count == 43, "SHA256 (32 bytes) should always encode to 43 Base64URL characters")

        return codeChallenge
    }
}
