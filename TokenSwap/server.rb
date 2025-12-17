require 'sinatra'
require 'net/http'
require 'net/https'
require 'base64'
require 'json'
require 'encrypted_strings'
require 'uri'

# Disable output buffering so logs appear immediately in Docker
$stdout.sync = true
$stderr.sync = true

# This is an example token swap service written
# as a Ruby/Sinatra service. This is required by
# the iOS SDK to authenticate a user.
#
# The service requires the Sinatra and
# encrypted_strings gems be installed:
#
# $ gem install sinatra encrypted_strings
#
# To run the service, enter your client ID, client
# secret and client callback URL below and run the
# project.
#
# $ ruby server.rb
#

CLIENT_ID = ENV['CLIENT_ID'] || raise("CLIENT_ID is not set")
CLIENT_SECRET = ENV['CLIENT_SECRET'] || raise("CLIENT_SECRET is not set")
ENCRYPTION_SECRET = ENV['ENCRYPTION_SECRET'] || raise("ENCRYPTION_SECRET is not set")
CLIENT_CALLBACK_URL = ENV['CLIENT_CALLBACK_URL'] || raise("CLIENT_CALLBACK_URL is not set")
AUTH_HEADER = "Basic " + Base64.strict_encode64(CLIENT_ID + ":" + CLIENT_SECRET)
SPOTIFY_ACCOUNTS_ENDPOINT = URI.parse("https://accounts.spotify.com")

SERVER_PORT = 1234 # The port to bind to.
SERVER_BIND = '0.0.0.0' # IP address of the interface to listen on (all)

set :port, SERVER_PORT 
set :bind, SERVER_BIND 

puts "\n==== SERVER STARTED ===="
puts "Client Id: #{CLIENT_ID}"
puts "Redirect URI: #{CLIENT_CALLBACK_URL}"
puts "Listening on #{SERVER_BIND}:#{SERVER_PORT}"
puts "======================="

post '/swap' do

    # This call takes a single POST parameter, "code", which
    # it combines with your client ID, secret and callback
    # URL to get an OAuth token from the Spotify Auth Service,
    # which it will pass back to the caller in a JSON payload.

    auth_code = params[:code]
    
    puts "\n==== /swap REQUEST ===="
    puts "Authorization code: #{auth_code[0..10]}..." if auth_code
    puts "Redirect URI: #{CLIENT_CALLBACK_URL}"
    puts "======================="

    http = Net::HTTP.new(SPOTIFY_ACCOUNTS_ENDPOINT.host, SPOTIFY_ACCOUNTS_ENDPOINT.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new("/api/token")

    request.add_field("Authorization", AUTH_HEADER)

    request.form_data = {
        "grant_type" => "authorization_code",
        "redirect_uri" => CLIENT_CALLBACK_URL,
        "code" => auth_code
    }

    puts "\n==== SPOTIFY API REQUEST ===="
    puts "Endpoint: POST #{SPOTIFY_ACCOUNTS_ENDPOINT}/api/token"
    puts "Grant Type: authorization_code"
    puts "============================="

    response = http.request(request)

    puts "\n==== SPOTIFY API RESPONSE ===="
    puts "Status: #{response.code}"
    
    # encrypt the refresh token before forwarding to the client
    if response.code.to_i == 200
        token_data = JSON.parse(response.body)
        puts "Response: SUCCESS"
        puts "Access Token: #{token_data['access_token'][0..20]}..." if token_data['access_token']
        puts "Refresh Token: #{token_data['refresh_token'][0..20]}..." if token_data['refresh_token']
        puts "Expires In: #{token_data['expires_in']} seconds"
        puts "Token Type: #{token_data['token_type']}"
        
        refresh_token = token_data["refresh_token"]
        encrypted_token = refresh_token.encrypt(:symmetric, :password => ENCRYPTION_SECRET)
        token_data["refresh_token"] = encrypted_token
        response.body = JSON.dump(token_data)
        
        puts "Encrypted Refresh Token: #{encrypted_token[0..20]}..."
    else
        puts "Response: ERROR"
        puts "Body: #{response.body}"
    end
    puts "==============================\n\n"

    status response.code.to_i
    return response.body
end

post '/refresh' do

    # Request a new access token using the POST:ed refresh token

    puts "\n==== /refresh REQUEST ===="
    encrypted_token = params[:refresh_token]
    puts "Encrypted Refresh Token: #{encrypted_token[0..20]}..." if encrypted_token
    puts "=========================="
    
    http = Net::HTTP.new(SPOTIFY_ACCOUNTS_ENDPOINT.host, SPOTIFY_ACCOUNTS_ENDPOINT.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new("/api/token")

    request.add_field("Authorization", AUTH_HEADER)

    refresh_token = encrypted_token.decrypt(:symmetric, :password => ENCRYPTION_SECRET)
    
    puts "\n==== SPOTIFY API REQUEST ===="
    puts "Endpoint: POST #{SPOTIFY_ACCOUNTS_ENDPOINT}/api/token"
    puts "Grant Type: refresh_token"
    puts "Refresh Token: #{refresh_token[0..20]}..." if refresh_token
    puts "============================="

    request.form_data = {
        "grant_type" => "refresh_token",
        "refresh_token" => refresh_token
    }

    response = http.request(request)

    puts "\n==== SPOTIFY API RESPONSE ===="
    puts "Status: #{response.code}"
    
    if response.code.to_i == 200
        token_data = JSON.parse(response.body)
        
        puts "Access Token: #{token_data['access_token'][0..20]}..." if token_data['access_token']
        puts "Expires In: #{token_data['expires_in']} seconds"
        puts "Token Type: #{token_data['token_type']}"        

         # Use refresh_token from response if exists, otherwise use the original refresh token
         if token_data['refresh_token']
            new_refresh_token = token_data['refresh_token']
            token_data['refresh_token'] = new_refresh_token.encrypt(:symmetric, :password => ENCRYPTION_SECRET)
            puts "New Refresh Token: #{token_data['refresh_token'][0..20]}..." if token_data['refresh_token']
        else
            token_data['refresh_token'] = encrypted_token
            puts "Refresh Token: #{token_data['refresh_token'][0..20]}..." if token_data['refresh_token']
        end
           
        response.body = JSON.dump(token_data)
    else
        puts "Response: ERROR"
        puts "Body: #{response.body}"
    end
    puts "==============================\n\n"

    status response.code.to_i
    return response.body

end
