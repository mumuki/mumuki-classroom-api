module Classroom
end

require 'mongoid'
require 'mumukit/core'
require 'mumukit/service'
require 'mumukit/inspection'
require 'mumukit/nuntius'
require 'mumukit/auth'
require 'mumukit/login'

Mongoid.load!('./config/mongoid.yml', ENV['RACK_ENV'] || 'development')

require_relative './class'
require_relative './consumer'
require_relative './profile'
require_relative './events'

require_relative './classroom/database'
require_relative './classroom/json_wrapper'

require_relative './classroom/models'
require_relative './classroom/collections'
require_relative './classroom/documents'
require_relative './classroom/reports'

require_relative './classroom/submissions'
require_relative './classroom/failed_submission'
require_relative './classroom/event'
require_relative './classroom/permissions_diff'
require_relative './classroom/permissions_persistence'

Mumukit::Nuntius.configure do |c|
  c.app_name = 'classroom'
  c.notification_mode = Mumukit::Nuntius::NotificationMode.from_env
end

Mumukit::Auth.configure do |c|
  c.client_ids = {
    auth: ENV['MUMUKI_AUTH_CLIENT_ID'],
    auth0: ENV['MUMUKI_AUTH0_CLIENT_ID']
  }
  c.client_secrets = {
    auth: ENV['MUMUKI_AUTH_CLIENT_SECRET'],
    auth0: ENV['MUMUKI_AUTH0_CLIENT_SECRET']
  }
  c.persistence_strategy = Classroom::PermissionsPersistence::Mongo.new
end

Mumukit::Login.configure do |config|
  config.user_class = User
  config.framework = Mumukit::Login::Framework::Sinatra
end

