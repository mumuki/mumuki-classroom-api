require_relative './lib/classroom'

raise 'Missing auth0 client_id' unless ENV['MUMUKI_AUTH0_CLIENT_ID']
raise 'Missing auth0 client_secret' unless ENV['MUMUKI_AUTH0_CLIENT_SECRET']

require_relative './app/routes'

run Sinatra::Application
