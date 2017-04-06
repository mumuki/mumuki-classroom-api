module Classroom
end

require 'mumukit/core'
require 'mumukit/service'
require 'mumukit/inspection'
require 'mumukit/nuntius'
require 'mumukit/auth'
require 'mumukit/login'

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
  c.client_id = Mumukit::Service::Env.auth0_client_id
  c.client_secret = Mumukit::Service::Env.auth0_client_secret
end

module Mumukit::Login::LoginControllerHelpers
  def save_current_user_session!(user)
    mumukit_controller.shared_session.tap do |it|
      it.uid = user.uid
      it.profile = {user_uid: user.uid,
                    user_name: user.name,
                    user_image_url: user.image_url}
    end
  end
end


Mumukit::Login.configure do |config|
  config.user_class = Classroom::Collection::Users
  config.framework = Mumukit::Login::Framework::Sinatra
end

