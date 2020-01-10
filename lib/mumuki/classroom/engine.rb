module Mumuki
  module Classroom
    class Engine < ::Rails::Engine
      endpoint Mumuki::Classroom::App
      config.generators.api_only = true
    end
  end
end
