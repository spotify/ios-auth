
Pod::Spec.new do |s|
  s.name             = 'Spotify-iOS-Auth'
  s.version          = '1.1.1'
  s.summary          = 'A lightweight framework that enables your application to obtain the authentication code from the Spotify app.'

  s.description      = <<-DESC
This is a lightweight framework that enables your application to obtain the authentication code from the Spotify app. Please note that this framework is currently under development and only supports a subset of the ios-sdk's functionalities. If you wish to use all features related to authentication, please utilize ios-sdk.
                       DESC

  s.homepage         = 'https://github.com/spotify/ios-auth'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'masakih' => 'masakih@spotify.com' }
  s.source           = { :git => 'https://github.com/spotify/ios-auth.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '11.0'

  s.vendored_frameworks = 'SpotifyLogin.xcframework'
 
end
