module Classroom
end

require 'mongoid'
require 'rouge'
require 'mumukit/core'
require 'mumukit/content_type'
require 'mumukit/service'
require 'mumukit/inspection'
require 'mumukit/nuntius'
require 'mumukit/auth'
require 'mumukit/login'
require 'mumukit/platform'

Mongoid.load!('./config/mongoid.yml', ENV['RACK_ENV'] || 'development')
I18n.load_translations_path File.join(__dir__, '..', 'config', 'locales', '*.yml')


module Mumuki
  module Classroom
    Nuntius = Mumukit::Nuntius::Component.new('classroom')
  end
end

require_relative './consumer'
require_relative './profile'
require_relative './events'

require_relative './classroom/models'
require_relative './classroom/reports'

require_relative './classroom/event'
require_relative './classroom/permissions_diff'

Mumukit::Nuntius.configure do |c|

end

Mumukit::Auth.configure do |_config|

end

Mumukit::Login.configure do |_config|

end

Mumukit::Platform.configure do |config|
  config.user_class = User
  config.organization_class = Organization
  config.application = Mumukit::Platform.classroom_api
  config.web_framework = Mumukit::Platform::WebFramework::Sinatra
end

class Mumukit::Platform::Model
  def self.demongoize(object)
    parse object
  end

  def self.mongoize(object)
    object.as_json
  end
end


module Mumukit::Platform::OrganizationMapping::Path
  class << self
    alias_method :__organization_name__, :organization_name

    def organization_name(request, domain)
      name = __organization_name__(request, domain)
      if %w(auth login logout).include? name
        'central'
      else
        name
      end
    end
  end
end
