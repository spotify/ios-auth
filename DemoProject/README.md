# SpotifyLoginDemoApp

A demo project that demonstrates how to use the Spotify iOSAuthSDK.

## Setup Instructions

1. **Install XcodeGen**  
   Run the following command to install XcodeGen via Homebrew:
   ```bash
   brew install xcodegen
   ```

2. **Generate the Xcode Project**  
   Navigate to this demo project directory and run:
   ```bash
   xcodegen
   ```

3. **Open the Project**  
   Open `SpotifyLoginDemo.xcodeproj` in Xcode.

4. **Create a Spotify App**  
   Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and create a new app:
   - Add any name and description for your app
   - Add a redirect URI in the format: `https://<your-domain>/<spotify-login-callback>`  
     (Replace `<your-domain>` and `<spotify-login-callback>` with your actual values)
   - Enable the **iOS SDK** checkbox
   - Click **Save**
   - Click **Edit Settings** and add the Bundle ID: `com.spotify.sdk.SpotifyLoginDemoApp`

5. **Add Your Client ID**  
   Copy your `clientID` from the Spotify Developer Dashboard and paste it into `ContentViewModel.swift`.

6. **Configure the Redirect URI**  
   Ensure your redirect URI is configured to open the sample app. If you're using a universal link as the redirect URI (recommended), update `SpotifyLoginDemoApp.entitlements` with your domain.
