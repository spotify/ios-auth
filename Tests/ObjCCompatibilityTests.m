#if __has_include(<SpotifyLogin/SpotifyLogin-Swift.h>)
#import <SpotifyLogin/SpotifyLogin-Swift.h>
#else
@import SpotifyLogin;
#endif
#import <XCTest/XCTest.h>

/**
 * Objective-C Compatibility Tests
 *
 * Purpose:
 * These tests ensure that the SpotifyLogin Swift SDK maintains full compatibility with Objective-C.
 * They verify that all public APIs, types, enums, and protocols are properly exposed and accessible
 * from Objective-C code through the generated Swift bridging header.
 *
 * Why we need these tests:
 * - The SpotifyLogin SDK is written in Swift but must be usable by Objective-C clients
 * - Rather than maintaining a separate Objective-C demo application (which would require ongoing
 *   maintenance and could fall out of sync), these automated tests serve as a living proof that
 *   the API works from Objective-C
 *
 * Note: These are compilation and basic functionality tests. Full integration testing is performed
 * by the Swift test suite and the SwiftUI demo application.
 */

@interface ObjCCompatibilityTests : XCTestCase <SPTSessionManagerDelegate>
@property (nonatomic, strong) SPTSessionManager *sessionManager;
@property (nonatomic, strong) SPTSession *receivedSession;
@property (nonatomic, strong) NSError *receivedError;
@end

@implementation ObjCCompatibilityTests

- (void)setUp
{
    [super setUp];
    self.receivedSession = nil;
    self.receivedError = nil;
}

- (void)tearDown
{
    self.sessionManager = nil;
    self.receivedSession = nil;
    self.receivedError = nil;
    [super tearDown];
}


#pragma mark - SPTConfiguration Tests

- (void)testConfigurationInitialization
{
    NSString *clientID = @"cd866ef8373c4cd7bf75551c4cc92066";
    NSURL *redirectURL = [NSURL URLWithString:@"myapp://spotify-callback"];

    SPTConfiguration *configuration = [[SPTConfiguration alloc] initWithClientID:clientID redirectURL:redirectURL];
    configuration.tokenSwapURL = [NSURL URLWithString:@"https://example.com/swap"];
    configuration.tokenRefreshURL = [NSURL URLWithString:@"https://example.com/refresh"];
    configuration.playURI = @"spotify:track:123";

    XCTAssertNotNil(configuration);
    XCTAssertEqualObjects(configuration.clientID, clientID);
    XCTAssertEqualObjects(configuration.redirectURL, redirectURL);
    XCTAssertNotNil(configuration.tokenSwapURL);
    XCTAssertNotNil(configuration.tokenRefreshURL);
    XCTAssertEqualObjects(configuration.playURI, @"spotify:track:123");
}

- (void)testConfigurationNSSecureCoding
{
    SPTConfiguration *originalConfiguration = [self createTestConfiguration];

    XCTAssertTrue([SPTConfiguration supportsSecureCoding]);

    NSError *error = nil;
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:originalConfiguration
                                                requiringSecureCoding:YES
                                                                error:&error];

    XCTAssertNotNil(encodedData);
    XCTAssertNil(error);

    SPTConfiguration *decodedConfiguration = [NSKeyedUnarchiver unarchivedObjectOfClass:[SPTConfiguration class]
                                                                               fromData:encodedData
                                                                                  error:&error];

    XCTAssertNotNil(decodedConfiguration);
    XCTAssertNil(error);
    XCTAssertEqualObjects(decodedConfiguration.clientID, originalConfiguration.clientID);
    XCTAssertEqualObjects(decodedConfiguration.redirectURL, originalConfiguration.redirectURL);
}

#pragma mark - SPTSession Tests

- (void)testSessionIsExpired
{
    // Note: Session creation with scopes is tested in Swift tests
    // Here we verify that the isExpired property is accessible from Objective-C
    // The actual expiration logic is tested in Swift tests
    XCTAssertTrue([SPTSession instancesRespondToSelector:@selector(isExpired)]);
}

- (void)testSessionNSSecureCoding
{
    // Verify that SPTSession conforms to NSSecureCoding protocol
    XCTAssertTrue([SPTSession supportsSecureCoding]);
    XCTAssertTrue([SPTSession conformsToProtocol:@protocol(NSSecureCoding)]);
}

#pragma mark - SPTSessionManager Tests

- (void)testSessionManagerInitialization
{
    SPTSessionManager *manager = [self createTestSessionManager];

    XCTAssertNotNil(manager);
    XCTAssertNil(manager.session);
}

- (void)testSessionManagerInitiateSession
{
    SPTSessionManager *manager = [self createTestSessionManager];

    // Test that initiateSession method is accessible from Objective-C
    NSArray<NSNumber *> *scopes = @[@(SPTScopePlaylistReadPrivate), @(SPTScopeUserReadEmail)];

    // This should not crash - we're just testing the API is accessible
    XCTAssertNoThrow([manager initiateSessionWithScope:scopes
                                     authorizationFlow:SPTAuthorizationFlowClientOnlyRedirectAppStore
                                              campaign:nil]);
}

- (void)testSessionManagerOpenURL
{
    SPTSessionManager *manager = [self createTestSessionManager];

    // Test openURL method - should return NO for invalid URL
    NSURL *invalidURL = [NSURL URLWithString:@"https://example.com"];
    BOOL result = [manager openURL:invalidURL];
    XCTAssertFalse(result);
}

- (void)testSessionManagerContinueUserActivity
{
    SPTConfiguration *configuration = [self createTestConfigurationWithRedirectURL:@"https://example.com/callback"];
    SPTSessionManager *manager = [[SPTSessionManager alloc] initWithConfiguration:configuration delegate:self];

    // Test continueUserActivity method - should be accessible from Objective-C
    // Create a non-browsing activity (should return NO)
    NSUserActivity *nonBrowsingActivity = [[NSUserActivity alloc] initWithActivityType:@"com.example.custom"];
    BOOL result = [manager continueUserActivity:nonBrowsingActivity];
    XCTAssertFalse(result);

    // Create a browsing activity without webpage URL (should return NO)
    NSUserActivity *browsingActivityNoURL = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    result = [manager continueUserActivity:browsingActivityNoURL];
    XCTAssertFalse(result);
}

- (void)testSessionManagerRenewSession
{
    SPTSessionManager *manager = [self createTestSessionManager];

    // Test renewSession method is accessible from Objective-C
    // Note: This will fail since there's no session, but we're testing API accessibility
    XCTAssertNoThrow([manager renewSession]);
}

#pragma mark - SPTSessionManagerDelegate Tests

- (void)testDelegateConformance
{
    // Test that the delegate protocol can be conformed to in Objective-C
    XCTAssertTrue([self conformsToProtocol:@protocol(SPTSessionManagerDelegate)]);
    XCTAssertTrue([self respondsToSelector:@selector(sessionManagerWithManager:didInitiate:)]);
    XCTAssertTrue([self respondsToSelector:@selector(sessionManagerWithManager:didFailWith:)]);
    XCTAssertTrue([self respondsToSelector:@selector(sessionManagerWithManager:didRenew:)]);
    XCTAssertTrue([self respondsToSelector:@selector(sessionManagerWithManager:shouldRequestAccessTokenWith:)]);
}

#pragma mark - SpotifyError Tests

- (void)testSpotifyErrorAccessibility
{
    // SpotifyError is a Swift Error enum that bridges to NSError through CustomNSError
    // The enum itself is NOT directly accessible from Objective-C, but when the SDK
    // returns errors through delegate methods, they bridge to NSError with the correct
    // domain and error codes.
    //
    // This test verifies that errors received from the SDK have the expected
    // domain and error codes that map to the SpotifyError enum values.

    SPTSessionManager *manager = [self createTestSessionManager];

    // Reset received error
    self.receivedError = nil;

    // Trigger a failure by calling renewSession without a session
    // This should result in a SpotifyError.renewSessionFailed being passed to the delegate
    [manager renewSession];

    // Verify the error was received with the correct domain and code
    XCTAssertNotNil(self.receivedError, @"Should have received an error from renewSession");
    XCTAssertEqualObjects(self.receivedError.domain,
                          @"com.spotify.sdk.SpotifyLogin",
                          @"Error domain should match SpotifyError.errorDomain");
    XCTAssertEqual(self.receivedError.code, 4, @"Error code should be 4 (renewSessionFailed)");
    XCTAssertNotNil(self.receivedError.localizedDescription, @"Error should have a localized description");
}


#pragma mark - Helpers

- (SPTConfiguration *)createTestConfiguration
{
    return [self createTestConfigurationWithRedirectURL:@"myapp://spotify-callback"];
}

- (SPTConfiguration *)createTestConfigurationWithRedirectURL:(NSString *)redirectURLString
{
    NSString *clientID = @"cd866ef8373c4cd7bf75551c4cc92066";
    NSURL *redirectURL = [NSURL URLWithString:redirectURLString];

    return [[SPTConfiguration alloc] initWithClientID:clientID redirectURL:redirectURL];
}

- (SPTSessionManager *)createTestSessionManager
{
    SPTConfiguration *configuration = [self createTestConfiguration];
    return [[SPTSessionManager alloc] initWithConfiguration:configuration delegate:self];
}

#pragma mark - SPTSessionManagerDelegate Implementation

- (void)sessionManagerWithManager:(SPTSessionManager *)manager didInitiate:(SPTSession *)session
{
    self.receivedSession = session;
}

- (void)sessionManagerWithManager:(SPTSessionManager *)manager didFailWith:(NSError *)error
{
    self.receivedError = error;
}

- (void)sessionManagerWithManager:(SPTSessionManager *)manager didRenew:(SPTSession *)session
{
    // Empty
}

- (BOOL)sessionManagerWithManager:(SPTSessionManager *)manager shouldRequestAccessTokenWith:(NSString *_Nonnull)code
{
    return NO;
}

@end
