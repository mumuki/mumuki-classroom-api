require 'mumukit/auth'

raise 'Missing auth0 client_id' unless ENV['MUMUKI_AUTH0_CLIENT_ID']
raise 'Missing auth0 client_secret' unless ENV['MUMUKI_AUTH0_CLIENT_SECRET']

Mumukit::Auth.configure do |c|
  c.client_id = ENV['MUMUKI_AUTH0_CLIENT_ID']
  c.client_secret = ENV['MUMUKI_AUTH0_CLIENT_SECRET']
end

require_relative './app/routes'

run Sinatra::Application
