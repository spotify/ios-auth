
Pod::Spec.new do |s|
  s.name             = 'Spotify-iOS-Auth'
  s.version          = '3.1.2'
  s.summary          = 'A lightweight framework that enables your application to authenticate users with Spotify.'

  s.description      = <<-DESC
This is a lightweight framework that enables your iOS application to authenticate users with Spotify and obtain access tokens for calling the Spotify Web API.
                       DESC

  s.homepage         = 'https://github.com/spotify/ios-auth'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = 'Spotify'
  s.source           = { :git => 'https://github.com/spotify/ios-auth.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'
  
  s.vendored_frameworks = 'SpotifyLogin.xcframework'
 
end
