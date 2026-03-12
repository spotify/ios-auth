import Foundation

enum Constant {
    enum Client {
        // To authenticate using the Spotify iOS app (if installed) you must allowlist the "spotify" scheme
        // in your app's info.plist using LSApplicationQueriesSchemes.
        static let urlScheme = "spotify:"
        static let actionScheme = "spotify-action:/"
        static let appStoreIdentifier = "324684580"
    }

    enum OAuth {
        static let serviceOriginURLString = "https://accounts.spotify.com"
        static let authorizeEndpoint = "/authorize"
        static let tokenEndpoint = "/api/token"

        // OAuth service parameter names.
        static let clientIDParameterName = "client_id"
        static let redirectURIParameterName = "redirect_uri"
        static let responseTypeParameterName = "response_type"
        static let scopeParameterName = "scope"
        static let scopeParameterSeparator = " "
        static let accessTokenParameterName = "access_token"
        static let refreshTokenParameterName = "refresh_token"
        static let codeParameterName = "code"
        static let grantTypeParameterName = "grant_type"
        static let expiresInParameterName = "expires_in"
        static let errorParameterName = "error"
        static let showDialogParameterName = "show_dialog"

        // OAuth error values.
        static let userCanceledErrorValue = "user_canceled"
        static let accessDeniedErrorValue = "access_denied"

        // OAuth service parameter values.
        static let codeResponseTypeParameterValue = "code"
        static let authorizationCodeGrantTypeParameterValue = "authorization_code"
        static let refreshTokenGrantTypeParameterValue = "refresh_token"
        static let showDialogParameterValue = "true"

        // PKCE parameter names and values.
        static let codeVerifierParameterName = "code_verifier"
        static let codeChallengeParameterName = "code_challenge"
        static let codeChallengeMethodParameterName = "code_challenge_method"
        static let s256CodeChallengeMethodParameterValue = "S256"
    }

    enum Query {
        static let noSignUpParameterName = "nosignup"
        static let noSignUpParameterValue = "true"
        static let noLinksParameterName = "nolinks"
        static let noLinksParameterValue = "true"
        static let utmSourceParameterName = "utm_source"
        static let utmMediumParameterName = "utm_medium"
        static let utmContentParameterName = "utm_content"
        static let utmCampaignParameterName = "utm_campaign"
    }
}
