# SpotifyLogin

## Overview
`SpotifyLogin` is a lightweight framework that enables your application to obtain the authentication code from the Spotify app. Please note that this framework is currently under development and only supports a subset of the [ios-sdk](https://github.com/spotify/ios-sdk)'s functionalities. If you wish to use all features related to authentication, please utilize [ios-sdk](https://github.com/spotify/ios-sdk).

## Minimum Requirement
iOS 11

## Usage
### Prepare Your Environment
- Install the latest version of Spotify from the App Store onto the device you will be using for development. Run the Spotify app and login or sign up.
- [Register Your Application](https://developer.spotify.com/documentation/web-api/concepts/apps#register-your-app). You will need to register your application at [My Applications](https://developer.spotify.com/dashboard) and obtain a client ID. When you register your app you will also need to allowlist a redirect URI that the Spotify app will use to callback to your app after authorization.

### Installation
- Add `SpotifyLogin.xcframework` to your project by dragging and dropping it in <b>Framworks, Libraries, and Embedded Content</b>
- In your info.plist add the following changes: 
   - Add your redirect URI you registered at My Applications. You will need to add your redirect URI under "URL types" and "URL Schemes". Be sure to set a unique "URL identifier" as well. More info on URL Schemes
   - Declare the Spotify’s URL scheme `spotify` by adding the `LSApplicationQueriesSchemes` key.
   
### Get authentication code
1. Initialise `Configuration` with your client ID and redirect URI.
```swift
import SpotifyLogin

let configuration = Configuration(clientID: "your_client_id", redirectURLString: "your_redirect_uri")
```
2. Initialise `SessionManager` with your configuration and set an object that conforms `SessionManagerDelegate` to the `delegate` of the instance.
```swift
let sessionManager = SessionManager(configuration: configuration)
sessionManager.delegate = <#delegate object#>
```
3. Implement `application(_:open:options:)` method to your `UIApplicationDelegate` and call sessionManager's `application(_:open:options:)` there.
```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return sessionManager.application(application, open: url, options: options)
    }
}
```
4. Start the authrization process with the scopes you need.
```swift
sessionManager.startAuthorizationCodeProcess(with: [.playlistModifyPublic, .playlistModifyPrivate])
```

