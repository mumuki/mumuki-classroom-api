module Classroom
end

require 'mumukit/core'
require 'mumukit/service'
require 'mumukit/inspection'
require 'mumukit/nuntius'
require 'mumukit/auth'

require_relative './class'
require_relative './consumer'
require_relative './profile'

require_relative './classroom/database'
require_relative './classroom/json_wrapper'

require_relative './classroom/collections'
require_relative './classroom/documents'
require_relative './classroom/reports'

require_relative './classroom/submission'
require_relative './classroom/failed_submission'
require_relative './classroom/event'
require_relative './classroom/permissions_diff'
require_relative './classroom/permissions_persistence'

Mumukit::Nuntius.configure do |c|
  c.app_name = 'classroom'
  c.notification_mode = Mumukit::Nuntius::NotificationMode.from_env
end

Mumukit::Auth.configure do |c|
  c.client_id = ENV['MUMUKI_AUTH0_CLIENT_ID']
  c.client_secret = ENV['MUMUKI_AUTH0_CLIENT_SECRET']
  c.persistence_strategy = Classroom::PermissionsPersistence::Mongo.new
end

