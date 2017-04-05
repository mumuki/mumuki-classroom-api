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

require_relative './consumer'
require_relative './profile'
require_relative './events'

require_relative './classroom/models'
require_relative './classroom/reports'

require_relative './classroom/event'
require_relative './classroom/permissions_diff'

Mumukit::Nuntius.configure do |c|
  c.app_name = 'classroom'
  c.notification_mode = Mumukit::Nuntius::NotificationMode.from_env
end

Mumukit::Auth.configure do |c|
  c.client_ids = {
    auth: ENV['MUMUKI_AUTH_CLIENT_ID']
  }
  c.client_secrets = {
    auth: ENV['MUMUKI_AUTH_CLIENT_SECRET']
  }
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
  config.user_class = User
  config.framework = Mumukit::Login::Framework::Sinatra
end

