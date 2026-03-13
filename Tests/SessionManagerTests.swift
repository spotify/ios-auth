@testable import SpotifyLogin

import XCTest

final class SessionManagerTests: XCTestCase {
    let clientID = "5fe01282e44241328a84e7c5cc169165"
    let redirectURL = URL(string: "https://example.com")!

    func testAuthorizeWithCampaign() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)

        // When
        let url = sessionManager.authorizationURL(with: [.playlistReadPrivate], campaign: "campaign-test")

        // Then
        if let query = url?.query {
            XCTAssertTrue(query.contains("utm_campaign=campaign-test"))
        } else {
            XCTFail("Invalid URL")
        }
    }

    func testAuthorizeWithoutCampaign() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)

        // When
        let url = sessionManager.authorizationURL(with: [.playlistReadPrivate])

        // Then
        if let query = url?.query {
            XCTAssertFalse(query.contains("utm_campaign="))
        } else {
            XCTFail("Invalid URL")
        }
    }

    func testGetAuthenticationCodeSuccess() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let code = "authenticationcode"
        let url = URL(string: redirectURL.absoluteString + "?code=" + code)!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockDelegate.code, code)
    }

    func testGetAuthenticationCodeFailure() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let url = redirectURL

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertFalse(result)
        XCTAssertNil(mockDelegate.code)
    }

    func testOpenURLWithMissingAuthorizationCode() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        // URL with valid scheme/host and query parameters but no code parameter
        let url = URL(string: redirectURL.absoluteString + "?state=some_state")!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertFalse(result, "Should return false when authorization code is missing")
        XCTAssertNil(mockDelegate.code, "Should not extract authorization code when it's missing")
        XCTAssertNotNil(mockDelegate.error, "Should report error to delegate")
        if let error = mockDelegate.error as? SpotifyError {
            XCTAssertEqual(error, SpotifyError.authorizationFailed, "Should report authorization failed error")
        } else {
            XCTFail("Error should be of type SpotifyError")
        }
    }

    func testOpenURLWithUserCanceledError() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let url = URL(string: redirectURL.absoluteString + "?error=user_canceled&error_description=User%20aborted")!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertTrue(result, "Should return true when URL contains error")
        XCTAssertNil(mockDelegate.code, "Should not extract authorization code when error present")
        XCTAssertNotNil(mockDelegate.error, "Should report error to delegate")
        if let error = mockDelegate.error as? SpotifyError {
            XCTAssertEqual(error, SpotifyError.authorizationCancelled, "Should report cancellation error")
        } else {
            XCTFail("Error should be of type SpotifyError")
        }
    }

    func testOpenURLWithAccessDeniedError() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let url = URL(string: redirectURL.absoluteString + "?error=access_denied&error_description=User%20denied%20access")!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertTrue(result, "Should return true when URL contains error")
        XCTAssertNil(mockDelegate.code, "Should not extract authorization code when error present")
        XCTAssertNotNil(mockDelegate.error, "Should report error to delegate")
        if let error = mockDelegate.error as? SpotifyError {
            XCTAssertEqual(error, SpotifyError.accessDenied, "Should report access denied error")
        } else {
            XCTFail("Error should be of type SpotifyError")
        }
    }

    func testOpenURLWithUnknownError() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let url = URL(string: redirectURL.absoluteString + "?error=invalid_request&error_description=Some%20other%20error")!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertTrue(result, "Should return true when URL contains error")
        XCTAssertNil(mockDelegate.code, "Should not extract authorization code when error present")
        XCTAssertNotNil(mockDelegate.error, "Should report error to delegate")
        if let error = mockDelegate.error as? SpotifyError {
            XCTAssertEqual(error, SpotifyError.authorizationFailed, "Should report generic authorization failed error for unknown errors")
        } else {
            XCTFail("Error should be of type SpotifyError")
        }
    }

    func testStringFromScope() {
        // Given
        let scopes: [Scope] = [.playlistReadPrivate, .playlistReadCollaborative]

        // When
        let string = SessionManager.string(from: scopes)

        // Then
        let scopeStringArray = string.split(separator: " ").map(String.init)
        XCTAssertEqual(scopes.map(\.name).sorted(), scopeStringArray.sorted())
    }

    func testStringFromScopeDuplicated() {
        // Given
        let scopes: [Scope] = [.playlistReadPrivate, .playlistReadCollaborative, .playlistReadCollaborative]
        let expected: [Scope] = [.playlistReadPrivate, .playlistReadCollaborative]

        // When
        let string = SessionManager.string(from: scopes)

        // Then
        let scopeStringArray = string.split(separator: " ").map(String.init)
        XCTAssertEqual(expected.map(\.name).sorted(), scopeStringArray.sorted())
    }

    // MARK: - PKCE Tests

    func testPKCEParametersInAuthorizationURL() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)

        // When
        let scopes: [Scope] = [.playlistReadPrivate]
        sessionManager.initiateSession(with: scopes, authorizationFlow: .clientOnlyRedirectAppStore)

        // Wait for PKCE generation
        let url = sessionManager.authorizationURL(with: scopes)

        // Then
        guard let query = url?.query else {
            XCTFail("Invalid URL")
            return
        }

        XCTAssertTrue(query.contains("code_challenge="), "Should contain code_challenge parameter")
        XCTAssertTrue(query.contains("code_challenge_method=S256"), "Should use S256 method")
    }

    func testPKCEParametersIncludedAfterInitiateSession() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)
        let scopes: [Scope] = [.playlistReadPrivate]

        // When
        sessionManager.initiateSession(with: scopes, authorizationFlow: .default)
        let urlWithPKCE = sessionManager.authorizationURL(with: scopes)

        // Then
        guard let queryWithPKCE = urlWithPKCE?.query else {
            XCTFail("URL should have query parameters")
            return
        }
        XCTAssertTrue(queryWithPKCE.contains("code_challenge="))
        XCTAssertTrue(queryWithPKCE.contains("code_challenge_method=S256"))
    }

    func testAuthorizationCodeFromURL() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)
        let expectedCode = "test_authorization_code_123"
        let url = URL(string: "\(redirectURL.absoluteString)?code=\(expectedCode)")!

        // When
        let code = sessionManager.authorizationCode(from: url)

        // Then
        XCTAssertEqual(code, expectedCode)
    }

    func testAuthorizationCodeFromURLNoCode() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)
        let url = URL(string: "\(redirectURL.absoluteString)?error=access_denied")!

        // When
        let code = sessionManager.authorizationCode(from: url)

        // Then
        XCTAssertNil(code)
    }

    // MARK: - Delegate Tests

    func testDelegateCalledOnAuthorizationCode() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let code = "test_code_123"
        let url = URL(string: "\(redirectURL.absoluteString)?code=\(code)")!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockDelegate.code, code)
    }

    func testDelegateNotCalledOnInvalidURL() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)
        let url = URL(string: "https://different-domain.com?code=test")!

        // When
        let result = sessionManager.openURL(url)

        // Then
        XCTAssertFalse(result)
        XCTAssertNil(mockDelegate.code)
    }

    func testAuthorizationCodeValidation() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)

        // Test valid URL
        let validURL = URL(string: "\(redirectURL.absoluteString)?code=valid_code")!
        XCTAssertNotNil(sessionManager.authorizationCode(from: validURL))
    }

    func testDefaultFlowURLGeneration() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)
        let scopes: [Scope] = [.playlistReadPrivate, .userReadEmail]

        // When
        let url = sessionManager.authorizationURL(with: scopes)

        // Then
        XCTAssertNotNil(url, "Authorization URL should be generated")
        guard let query = url?.query else {
            XCTFail("URL should have query parameters")
            return
        }

        // Verify essential OAuth parameters
        XCTAssertTrue(query.contains("client_id=\(clientID)"))
        XCTAssertTrue(query.contains("redirect_uri="))
        XCTAssertTrue(query.contains("response_type=code"))
        XCTAssertTrue(query.contains("scope="))
        XCTAssertTrue(query.contains("playlist-read-private"))
        XCTAssertTrue(query.contains("user-read-email"))
    }

    // MARK: - Session Token Response Handling Tests

    func testHandleAccessTokenResponseSuccess() throws {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        let accessToken = "test_access_token_123"
        let refreshToken = "test_refresh_token_456"
        let expiresIn: TimeInterval = 3600
        let scopes = "user-read-email playlist-read-private"

        let json: [String: Any] = [
            "access_token": accessToken,
            "refresh_token": refreshToken,
            "expires_in": expiresIn,
            "scope": scopes,
        ]

        let data = try XCTUnwrap(JSONSerialization.data(withJSONObject: json))

        // When
        sessionManager.handleAccessTokenResponse(data: data, error: nil, refreshToken: nil, isRenewal: false)

        // Then
        XCTAssertNotNil(mockDelegate.initiatedSession, "Session should be initiated")
        XCTAssertEqual(mockDelegate.initiatedSession?.accessToken, accessToken)
        XCTAssertEqual(mockDelegate.initiatedSession?.refreshToken, refreshToken)
        XCTAssertNil(mockDelegate.error, "No error should be reported")
    }

    func testHandleAccessTokenResponseWithMissingFields() throws {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        // Missing refresh_token
        let json: [String: Any] = [
            "access_token": "test_token",
            "expires_in": 3600,
        ]

        let data = try XCTUnwrap(JSONSerialization.data(withJSONObject: json))

        // When
        sessionManager.handleAccessTokenResponse(data: data, error: nil, refreshToken: nil, isRenewal: false)

        // Then
        XCTAssertNil(mockDelegate.initiatedSession, "Session should not be created with missing fields")
        XCTAssertNotNil(mockDelegate.error, "Error should be reported")
    }

    func testHandleAccessTokenResponseWithError() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        let error = NSError(domain: "TestError", code: -1, userInfo: nil)

        // When
        sessionManager.handleAccessTokenResponse(data: nil, error: error, refreshToken: nil, isRenewal: false)

        // Then
        XCTAssertNil(mockDelegate.initiatedSession, "Session should not be created on error")
        XCTAssertNotNil(mockDelegate.error, "Error should be reported")
    }

    func testHandleAccessTokenResponseWithOAuthError() throws {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        let json: [String: Any] = [
            "error": "invalid_grant",
            "error_description": "Invalid authorization code",
        ]

        let data = try XCTUnwrap(JSONSerialization.data(withJSONObject: json))

        // When
        sessionManager.handleAccessTokenResponse(data: data, error: nil, refreshToken: nil, isRenewal: false)

        // Then
        XCTAssertNil(mockDelegate.initiatedSession, "Session should not be created when OAuth error is present")
        XCTAssertNotNil(mockDelegate.error, "Error should be reported")
    }

    func testHandleAccessTokenResponseInvalidJSON() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        let invalidData = "invalid json".data(using: .utf8)!

        // When
        sessionManager.handleAccessTokenResponse(data: invalidData, error: nil, refreshToken: nil, isRenewal: false)

        // Then
        XCTAssertNil(mockDelegate.initiatedSession, "Session should not be created with invalid JSON")
        XCTAssertNotNil(mockDelegate.error, "Error should be reported")
    }

    // MARK: - Session Renewal Tests

    func testRenewSessionSuccess() throws {
        // Given - Create a mock URLSession with successful response
        let mockURLSession = createMockURLSession(
            responseData: try createSuccessfulRenewalResponse(),
            statusCode: 200,
            error: nil
        )

        let mockDelegate = MockDelegate()
        let expectation = XCTestExpectation(description: "Session renewal completes")
        mockDelegate.didRenewExpectation = expectation // Set the expectation

        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(
            configuration: configuration,
            delegate: mockDelegate,
            urlSession: mockURLSession
        )

        // Set up an existing session
        let existingSession = Session(
            accessToken: "old_access_token",
            refreshToken: "test_refresh_token",
            expirationDate: Date(timeIntervalSinceNow: -100), // expired
            scopes: [.userReadEmail]
        )
        sessionManager.session = existingSession

        // When
        sessionManager.renewSession()

        // Wait for the delegate to be called
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(mockDelegate.renewedSession, "Renewed session should be created")
        XCTAssertEqual(mockDelegate.renewedSession?.accessToken, "new_access_token_789", "Access token should be updated")
        XCTAssertEqual(mockDelegate.renewedSession?.refreshToken, "new_refresh_token_012", "Refresh token should be updated")
        XCTAssertNil(mockDelegate.error, "No error should occur on successful renewal")
        XCTAssertNil(mockDelegate.initiatedSession, "Should use didRenew delegate method, not didInitiate")

        // Clean up
        MockURLProtocol.reset()
    }

    func testRenewSessionWithoutExistingSession() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        // No session set
        XCTAssertNil(sessionManager.session)

        // When
        sessionManager.renewSession()

        // Then
        XCTAssertNotNil(mockDelegate.error, "Error should be reported when no session exists")
    }

    func testRenewSessionNetworkFailure() {
        // Given - Create a mock URLSession with network error
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let mockURLSession = createMockURLSession(
            responseData: nil,
            statusCode: 0,
            error: networkError
        )

        let mockDelegate = MockDelegate()
        let expectation = XCTestExpectation(description: "Session renewal fails")
        mockDelegate.didFailExpectation = expectation // Set the expectation

        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(
            configuration: configuration,
            delegate: mockDelegate,
            urlSession: mockURLSession
        )

        // Set up an existing session
        let existingSession = Session(
            accessToken: "old_access_token",
            refreshToken: "test_refresh_token",
            expirationDate: Date(timeIntervalSinceNow: -100),
            scopes: [.userReadEmail]
        )
        sessionManager.session = existingSession

        // When
        sessionManager.renewSession()

        // Wait for the delegate to be called
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(mockDelegate.error, "Error should be reported on network failure")
        XCTAssertNil(mockDelegate.renewedSession, "No session should be renewed on failure")
        let reportedError = mockDelegate.error as? SpotifyError
        XCTAssertEqual(reportedError, SpotifyError.renewSessionFailed, "Should report renewal-specific error")

        // Clean up
        MockURLProtocol.reset()
    }

    func testHandleRenewalResponseSuccess() throws {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        // Set up an existing session
        let existingRefreshToken = "existing_refresh_token"
        let existingSession = Session(
            accessToken: "old_token",
            refreshToken: existingRefreshToken,
            expirationDate: Date(timeIntervalSinceNow: -100),
            scopes: [.userReadEmail]
        )
        sessionManager.session = existingSession

        let newAccessToken = "new_access_token_789"
        let newRefreshToken = "new_refresh_token_012"
        let expiresIn: TimeInterval = 3600
        let scopes = "user-read-email"

        let json: [String: Any] = [
            "access_token": newAccessToken,
            "refresh_token": newRefreshToken,
            "expires_in": expiresIn,
            "scope": scopes,
        ]

        let data = try XCTUnwrap(JSONSerialization.data(withJSONObject: json))

        // When
        sessionManager.handleAccessTokenResponse(data: data, error: nil, refreshToken: existingRefreshToken, isRenewal: true)

        // Then
        XCTAssertNotNil(mockDelegate.renewedSession, "Renewed session should be reported to delegate")
        XCTAssertEqual(mockDelegate.renewedSession?.accessToken, newAccessToken)
        XCTAssertEqual(mockDelegate.renewedSession?.refreshToken, newRefreshToken)
        XCTAssertNil(mockDelegate.error, "No error should be reported on successful renewal")
        XCTAssertNil(mockDelegate.initiatedSession, "Should use didRenew, not didInitiate")
    }

    func testHandleRenewalResponseError() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        let error = NSError(domain: "TestError", code: -1, userInfo: nil)

        // When
        sessionManager.handleAccessTokenResponse(data: nil, error: error, refreshToken: nil, isRenewal: true)

        // Then
        XCTAssertNil(mockDelegate.renewedSession, "No session should be renewed on error")
        XCTAssertNotNil(mockDelegate.error, "Error should be reported")
        let reportedError = mockDelegate.error as? SpotifyError
        XCTAssertEqual(reportedError, SpotifyError.renewSessionFailed, "Should report renewal-specific error")
    }

    // MARK: - Request Access Token Tests

    func testRequestAccessTokenWithDelegateShouldNotRequest() {
        // Given
        let mockDelegate = MockDelegate()
        mockDelegate.shouldRequestTokenReturnValue = false
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        // Set up PKCE
        sessionManager.initiateSession(with: [.userReadEmail], authorizationFlow: .default)

        let authCode = "test_auth_code"

        // When
        sessionManager.requestAccessToken(with: authCode)

        // Then
        XCTAssertEqual(mockDelegate.code, authCode, "Delegate should receive the auth code")
        XCTAssertNil(mockDelegate.initiatedSession, "No session should be initiated when delegate returns false")
    }

    func testRequestAccessTokenWithoutPKCE() {
        // Given
        let mockDelegate = MockDelegate()
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        let sessionManager = SessionManager(configuration: configuration, delegate: mockDelegate)

        // Don't call initiateSession, so no PKCE is set
        let authCode = "test_auth_code"

        // When
        sessionManager.requestAccessToken(with: authCode)

        // Then
        XCTAssertNotNil(mockDelegate.error, "Error should be reported when PKCE is missing")
    }

    // MARK: - Configuration Tests

    func testAuthorizationURLWithoutPKCEWhenTokenSwapConfigured() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        configuration.tokenSwapURL = URL(string: "https://example.com/api/token")!
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)
        let scopes: [Scope] = [.playlistReadPrivate]

        // When
        sessionManager.initiateSession(with: scopes, authorizationFlow: .default)
        let url = sessionManager.authorizationURL(with: scopes)

        // Then
        guard let query = url?.query else {
            XCTFail("Invalid URL")
            return
        }

        XCTAssertFalse(query.contains("code_challenge="), "Should NOT include PKCE parameters when using token swap")
        XCTAssertFalse(query.contains("code_challenge_method="), "Should NOT include PKCE method when using token swap")
    }

    func testAuthorizationURLWithPKCEWhenNoTokenSwap() {
        // Given
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        // Don't set tokenSwapURL - should use PKCE
        let sessionManager = SessionManager(configuration: configuration, delegate: nil)
        let scopes: [Scope] = [.playlistReadPrivate]

        // When
        sessionManager.initiateSession(with: scopes, authorizationFlow: .default)
        let url = sessionManager.authorizationURL(with: scopes)

        // Then
        guard let query = url?.query else {
            XCTFail("Invalid URL")
            return
        }

        XCTAssertTrue(query.contains("code_challenge="), "Should include PKCE parameters when not using token swap")
        XCTAssertTrue(query.contains("code_challenge_method=S256"), "Should include PKCE S256 method")
    }

    func testRequestAccessTokenWithTokenSwap() throws {
        // Given
        let tokenSwapURL = URL(string: "https://example.com/api/token")!
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        configuration.tokenSwapURL = tokenSwapURL

        let mockURLSession = createMockURLSession(
            responseData: try createSuccessfulTokenResponse(),
            statusCode: 200,
            error: nil
        )

        let mockDelegate = MockDelegate()
        let expectation = XCTestExpectation(description: "Token swap completes")
        mockDelegate.didInitiateExpectation = expectation

        let sessionManager = SessionManager(
            configuration: configuration,
            delegate: mockDelegate,
            urlSession: mockURLSession
        )

        let authCode = "test_auth_code_123"

        // When
        sessionManager.requestAccessToken(with: authCode)

        // Wait for the delegate to be called
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(mockDelegate.initiatedSession, "Session should be initiated via token swap")
        XCTAssertNil(mockDelegate.error, "No error should occur")

        // Clean up
        MockURLProtocol.reset()
    }

    func testRenewSessionWithCustomTokenRefreshURL() throws {
        // Given
        let tokenRefreshURL = URL(string: "https://example.com/api/refresh")!
        let configuration = Configuration(clientID: clientID, redirectURL: redirectURL)
        configuration.tokenRefreshURL = tokenRefreshURL

        let mockURLSession = createMockURLSession(
            responseData: try createSuccessfulRenewalResponse(),
            statusCode: 200,
            error: nil
        )

        let mockDelegate = MockDelegate()
        let expectation = XCTestExpectation(description: "Session renewal completes")
        mockDelegate.didRenewExpectation = expectation

        let sessionManager = SessionManager(
            configuration: configuration,
            delegate: mockDelegate,
            urlSession: mockURLSession
        )

        // Set up an existing session
        let existingSession = Session(
            accessToken: "old_access_token",
            refreshToken: "test_refresh_token",
            expirationDate: Date(timeIntervalSinceNow: -100),
            scopes: [.userReadEmail]
        )
        sessionManager.session = existingSession

        // When
        sessionManager.renewSession()

        // Wait for the delegate to be called
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(mockDelegate.renewedSession, "Session should be renewed with custom URL")
        XCTAssertNil(mockDelegate.error, "No error should occur")

        // Clean up
        MockURLProtocol.reset()
    }
}


// MARK: - Helper Methods

extension SessionManagerTests {
    func createMockURLSession(responseData: Data?, statusCode: Int, error: Error?) -> URLSession {
        MockURLProtocol.mockData = responseData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://accounts.spotify.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        MockURLProtocol.mockError = error

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func createSuccessfulRenewalResponse() throws -> Data {
        let json: [String: Any] = [
            "access_token": "new_access_token_789",
            "refresh_token": "new_refresh_token_012",
            "expires_in": 3600,
            "scope": "user-read-email",
        ]
        return try XCTUnwrap(JSONSerialization.data(withJSONObject: json))
    }

    func createSuccessfulTokenResponse() throws -> Data {
        let json: [String: Any] = [
            "access_token": "test_access_token_123",
            "refresh_token": "test_refresh_token_456",
            "expires_in": 3600,
            "scope": "user-read-email playlist-read-private",
        ]
        return try XCTUnwrap(JSONSerialization.data(withJSONObject: json))
    }
}

private class MockDelegate: SessionManagerDelegate {
    private(set) var code: String?
    private(set) var initiatedSession: Session?
    private(set) var renewedSession: Session?
    private(set) var error: Error?
    var shouldRequestTokenReturnValue = true

    // Add expectation properties
    var didInitiateExpectation: XCTestExpectation?
    var didRenewExpectation: XCTestExpectation?
    var didFailExpectation: XCTestExpectation?

    func sessionManager(manager: SessionManager, didInitiate session: Session) {
        self.initiatedSession = session
        didInitiateExpectation?.fulfill()
    }

    func sessionManager(manager: SessionManager, didRenew session: Session) {
        self.renewedSession = session
        didRenewExpectation?.fulfill()
    }

    func sessionManager(manager: SessionManager, didFailWith error: Error) {
        self.error = error
        didFailExpectation?.fulfill()
    }

    func sessionManager(manager: SessionManager, shouldRequestAccessTokenWith code: String) -> Bool {
        self.code = code
        return shouldRequestTokenReturnValue
    }

    func reset() {
        code = nil
        initiatedSession = nil
        renewedSession = nil
        error = nil
        didInitiateExpectation = nil
        didRenewExpectation = nil
        didFailExpectation = nil
    }
}

// MARK: - Mock URLProtocol for Testing Network Requests

private class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: HTTPURLResponse?
    static var mockError: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = MockURLProtocol.mockResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = MockURLProtocol.mockData {
                client?.urlProtocol(self, didLoad: data)
            }
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
    }
}
