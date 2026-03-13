import Foundation

// MARK: - URL Form Encoding Extension

extension [String: String] {
    func formURLEncodedData() -> Data? {
        var components = URLComponents()
        components.queryItems = map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.query?.data(using: .utf8)
    }
}

// MARK: - Base64URL Encoding Extension

extension Data {
    /// Encode data to Base64URL format (URL-safe alphabet with no padding).
    /// This is required by RFC 7636 for PKCE.
    /// - Returns: Base64URL encoded string
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
