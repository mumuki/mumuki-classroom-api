module Mumuki
  module Classroom
    INDEXES = []

    def self.create_indexes!
      INDEXES.each { |it| it.create_indexes }
    end

    def self.register_index!(clazz)
      INDEXES << clazz
    end
  end
end


require 'mumukit/platform'
require 'mongoid'
require 'mumuki/domain'
require 'mumukit/login'
require 'mumukit/nuntius'
require 'mumukit/inspection'

I18n.load_translations_path File.join(__dir__, 'classroom', 'locales', '*.yml')

require_relative './profile'

require_relative './classroom/models'
require_relative './classroom/reports'

require_relative './classroom/collection'
require_relative './classroom/event'
require_relative './classroom/permissions_diff'

Mulang::Inspection.register_extension! Mumukit::Inspection::Css

Mumukit::Nuntius.configure do |c|
  c.app_name = 'classroom'
end

Mumukit::Platform.configure do |config|
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

require_relative './classroom/sinatra'
require_relative './classroom/engine'
