# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

# Action Cable uses EventMachine which requires that all classes are loaded in advance
Rails.application.eager_load!
require 'action_cable/process/logging'

Mumukit::Auth.configure do |c|
  c.client_id = ENV['MUMUKI_AUTH0_CLIENT_ID']
  c.client_secret = ENV['MUMUKI_AUTH0_CLIENT_SECRET']
end

run Rails.application
