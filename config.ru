if ENV['RAILS_ENV'] == 'development' || ENV['RACK_ENV'] == 'development'
  ENV['MUMUKI_ORGANIZATION_MAPPING'] ||= 'path'
end

require_relative './lib/classroom'
require_relative './app/routes'

run Sinatra::Application
