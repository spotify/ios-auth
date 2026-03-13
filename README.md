# SpotifyLogin

## Overview

`SpotifyLogin` is a lightweight framework that enables your iOS application to authenticate users with Spotify and obtain access tokens for calling the Spotify Web API. The SDK handles the complete OAuth 2.0 authorization flow, including PKCE (Proof Key for Code Exchange) for secure authentication.

### Minimum Requirements

- iOS 13.0 or later

### Features

- ✅ Seamless authentication via Spotify iOS app or web browser
- ✅ Automatic PKCE implementation for secure OAuth 2.0 flow
- ✅ Multiple authorization flows to fit different use cases
- ✅ Automatic token exchange and session management
- ✅ Optional manual code exchange for custom implementations
- ✅ Support for both Universal Links (recommended) and custom URL schemes
- ✅ Token refresh capability for long-lived sessions

## Table of Contents

- [Getting Started](#getting-started)
  - [Prepare Your Environment](#prepare-your-environment)
  - [Installation](#installation)
  - [Setup](#setup)
- [Usage](#usage)
  - [Configuration](#configuration)
  - [SessionManager](#sessionmanager)
  - [Implement SessionManagerDelegate](#implement-sessionmanagerdelegate)
  - [Handle Redirect Callbacks](#handle-redirect-callbacks)
  - [Start Authorization](#start-authorization)
- [Authorization Flows](#authorization-flows)
- [PKCE vs Token Swap](#pkce-vs-token-swap)
- [Manual Code Exchange](#manual-code-exchange)
- [Checking Spotify App Installation](#checking-spotify-app-installation)
- [Token Refresh](#token-refresh)
- [Campaign Attribution](#campaign-attribution)
- [Storing Sessions Securely](#storing-sessions-securely)
- [Error Handling](#error-handling)
- [Demo Project](#demo-project)
- [Support](#support)
- [License](#license)

## Getting Started

### Prepare Your Environment

[Register your application](https://developer.spotify.com/documentation/web-api/concepts/apps#register-your-app) at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) to obtain a **Client ID**. During registration, you must configure a **Redirect URI** that Spotify will use to call back to your app after authorization.

**Important:** Make sure to add your **bundle ID** and enable the **iOS SDK** option in your app settings on the Developer Dashboard.

### Installation

The SDK can be integrated into your project using one of the following methods:

#### Manually (XCFramework)

1. Download the `SpotifyLogin.xcframework` from the [latest release](https://github.com/spotify/ios-auth/releases)
2. Add `SpotifyLogin.xcframework` to your project by dragging and dropping it into **Frameworks, Libraries, and Embedded Content** in your Xcode project settings
3. Make sure the framework is set to **Embed & Sign**

#### Swift Package Manager

Add the SDK as a dependency in your `Package.swift` or directly in Xcode:

```swift
    .package(url: "https://github.com/spotify/ios-auth.git", from: "3.1.2")
]
```

#### CocoaPods

To integrate using [CocoaPods](https://cocoapods.org/), add the following to your `Podfile`:

```ruby
pod 'Spotify-iOS-Auth', '~> 3.1.2'
```

### Setup

After installation, configure the following:

- Add the Spotify scheme to your app's `Info.plist` file:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>spotify</string>
</array>
```

- Configure your Redirect URI:

   **Option A: Universal Links (Recommended)**
   - Use an `https://` redirect URI (e.g., `https://yourdomain.com/spotify-callback`)
   - Set up Associated Domains in **Signing & Capabilities**:
     - Add `applinks:yourdomain.com`
     - Add `webcredentials:yourdomain.com`
     - Configure your domain's [.well-known/apple-app-site-association](https://developer.apple.com/documentation/xcode/supporting-associated-domains) file

   **Option B: Custom URL Scheme**
   - Use a custom scheme (e.g., `myapp://callback`)
   - Add your redirect URI under **URL Types** in your [project settings](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app):
     - **URL Schemes:** `myapp`
     - **Identifier:** A unique identifier (e.g., `com.yourcompany.myapp`)

## Usage

### Configuration

Initialize a `Configuration` object with your Client ID and Redirect URI:

```swift
import SpotifyLogin

let configuration = Configuration(
    clientID: "your_client_id",
    redirectURL: URL(string: "your_redirect_uri")!
)
```

### SessionManager

Initialize a `SessionManager` with your configuration and assign a delegate that conforms to `SessionManagerDelegate`:

```swift
let sessionManager = SessionManager(configuration: configuration, delegate: self)
```

### Implement SessionManagerDelegate

Handle authentication success and failure:

```swift
extension YourClass: SessionManagerDelegate {
    func sessionManager(manager: SessionManager, didInitiate session: Session) {
        // Authentication successful - use session.accessToken for API calls
        print("Access Token: \(session.accessToken)")
        print("Expires: \(session.expirationDate)")
    }

    func sessionManager(manager: SessionManager, didFailWith error: Error) {
        // Authentication failed
        print("Auth failed: \(error.localizedDescription)")
    }
}
```

### Handle Redirect Callbacks

Configure your app to handle the redirect callback from Spotify.

**For UIKit with SceneDelegate:**

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // Use this method if your redirect URI is a custom URL scheme
    guard let url = URLContexts.first?.url else { return }
    sessionManager.openURL(url)
}

func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    // Use this method if your redirect URI is a universal link (https)
    sessionManager.continueUserActivity(userActivity)
}
```

**For SwiftUI:**

```swift
.onOpenURL { url in
    sessionManager.openURL(url)
}
```

### Start Authorization

Initiate the authorization flow with the scopes your app needs:

```swift
let scopes: [Scope] = [.playlistModifyPublic, .playlistReadPrivate]
sessionManager.initiateSession(with: scopes)
```

See the full list of available scopes in `Scope.swift` or the [Spotify Web API documentation](https://developer.spotify.com/documentation/web-api/concepts/scopes).

## Authorization Flows

The SDK supports four different authorization flows to accommodate various use cases. Specify the flow when calling `initiateSession`:

### 1. `.default` (Recommended)

The most user-friendly flow with automatic fallback:

1. If Spotify app is installed → Opens Spotify app for authentication
2. If Spotify app is not installed → Opens web browser (ASWebAuthenticationSession)

**Use this when:** You want the best user experience with automatic fallback.

```swift
sessionManager.initiateSession(with: scopes, authorizationFlow: .default)
```

### 2. `.clientOnlyRedirectAppStore`

Encourages users to install the Spotify app:

1. If Spotify app is installed → Opens Spotify app for authentication
2. If Spotify app is not installed → Redirects to App Store

**Use this when:** You require authentication through the Spotify app only.

```swift
sessionManager.initiateSession(with: scopes, authorizationFlow: .clientOnlyRedirectAppStore)
```

### 3. `.clientOnlyFailsIfNotInstalled`

Strict app-only authentication:

1. If Spotify app is installed → Opens Spotify app for authentication
2. If Spotify app is not installed → Fails with error

**Use this when:** You require authentication through the Spotify app only.

```swift
sessionManager.initiateSession(with: scopes, authorizationFlow: .clientOnlyFailsIfNotInstalled)
```

### 4. `.spotifySchemeNotRegistered`

Special flow for apps that cannot declare the Spotify URL scheme:

1. Attempts to open Spotify app directly (without checking `canOpenURL`)
2. If opening fails → Falls back to web browser

**Use this when:** You've reached the limit of `LSApplicationQueriesSchemes` in your `Info.plist` and cannot add the `spotify` scheme.

```swift
sessionManager.initiateSession(with: scopes, authorizationFlow: .spotifySchemeNotRegistered)
```

## PKCE vs Token Swap

The SDK supports two methods for exchanging authorization codes for access tokens:

**PKCE (Proof Key for Code Exchange)** is a secure OAuth 2.0 extension designed for mobile and native applications.

It's the default behavior, no additional configuration needed:

```swift
let configuration = Configuration(
    clientID: "your_client_id",
    redirectURL: URL(string: "your_redirect_uri")!
)
let sessionManager = SessionManager(configuration: configuration, delegate: self)
sessionManager.initiateSession(with: scopes)
// SDK automatically handles PKCE and token exchange
```

**Token Swap** is an approach where your backend server exchanges the authorization code for tokens.

Configure token swap and refresh URLs:

```swift
let configuration = Configuration(
    clientID: "your_client_id",
    redirectURL: URL(string: "your_redirect_uri")!
)
configuration.tokenSwapURL = URL(string: "https://yourbackend.com/api/token")
configuration.tokenRefreshURL = URL(string: "https://yourbackend.com/api/refresh_token")

let sessionManager = SessionManager(configuration: configuration, delegate: self)
sessionManager.initiateSession(with: scopes)
// SDK will use token swap instead of PKCE
```

Your backend server needs two endpoints:
- `/swap` - Exchanges authorization code for access token
- `/refresh` - Refreshes an expired access token

For testing, we provide a complete Ruby/Sinatra token swap server that you can run with Docker:

  ```bash
  cd TokenSwap
  docker-compose up
  ```
 
The server will start on `http://localhost:1234`.

For more details, see the [TokenSwap/README](TokenSwap/README.md).

## Manual Code Exchange

The SDK provides automatic token exchange by default, but you can handle it manually if needed for custom requirements.

Implement the optional `shouldRequestAccessTokenWith` delegate method:

```swift
extension YourClass: SessionManagerDelegate {
    // Return false to handle token exchange manually
    func sessionManager(manager: SessionManager, shouldRequestAccessTokenWith code: String) -> Bool {
        // Perform manual exchange
        exchangeCodeForToken(code)
        return false // Tell SDK not to do automatic exchange
    }
}

```

## Checking Spotify App Installation

Check if the Spotify app is installed before initiating authorization:

```swift
if sessionManager.isSpotifyAppInstalled {
    print("Spotify is installed")
} else {
    print("Spotify is not installed")
}
```
**Note:** This requires the `spotify` scheme in `LSApplicationQueriesSchemes`.

## Token Refresh

Access tokens are short-lived and expire after a period of time (typically 1 hour). When an access token expires, you'll need to refresh it to continue making API calls.

Check if your current session's access token has expired and manually trigger a token refresh:

```swift
if session.isExpired {
    sessionManager.renewSession()
}
```

Implement the `didRenew` delegate method to receive the new access token:

```swift
extension YourClass: SessionManagerDelegate {
    func sessionManager(manager: SessionManager, didRenew session: Session) {
        // Handle successful token refresh
        print("Token renewed successfully")
        print("New Access Token: \(session.accessToken)")
        print("Expires at: \(session.expirationDate)")

        // Update your stored session if you're persisting it
    }
}
```

Token renewal can fail for various reasons (network issues, expired refresh token, revoked access). Handle failures appropriately:

```swift
func sessionManager(manager: SessionManager, didFailWith error: Error) {
    if let spotifyError = error as? SpotifyError {
        switch spotifyError {
        case .renewSessionFailed:
            // Prompt user to log in again
            sessionManager.initiateSession(with: requiredScopes)
        ...
        }
    }
}
```

**Note:** If token refresh fails (e.g., refresh token has expired), you'll need to initiate a new authorization flow to obtain a fresh access token.

## Campaign Attribution

Track where users are coming from by adding a campaign parameter:

```swift
sessionManager.initiateSession(
    with: scopes,
    authorizationFlow: .default,
    campaign: "summer_promotion"
)
```

## Storing Sessions Securely

The `Session` object conforms to `NSSecureCoding` for secure storage:

```swift
// Save session
if let session = sessionManager.session {
    let data = try? NSKeyedArchiver.archivedData(
        withRootObject: session,
        requiringSecureCoding: true
    )
    // Store in Keychain or secure storage
}

// Restore session
if let data = loadFromKeychain() {
    let session = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: Session.self,
        from: data
    )
    sessionManager.session = session
}
```

## Error Handling

The SDK provides detailed error information through `SpotifyError`:

```swift
func sessionManager(manager: SessionManager, didFailWith error: Error) {
    if let spotifyError = error as? SpotifyError {
        switch spotifyError {
        case .authorizationCancelled:
            print("User cancelled authorization")
        case .accessDenied:
            print("User denied access")
        case .authorizationFailed:
            print("Authorization failed")
        case .renewSessionFailed:
            print("Token refresh failed")
        }
    }
}
```

## Demo Project

The SDK includes a complete demo project showing best practices. See the `DemoProject` folder for a working example using SwiftUI.

## Support

For issues and questions:
- Check the [Spotify Developer Documentation](https://developer.spotify.com/documentation/)
- Review the demo project included with the SDK
- Open an issue on the [GitHub repository](https://github.com/spotify/ios-auth)

## License

This SDK is licensed under the Apache License 2.0. See the LICENSE file for details.
