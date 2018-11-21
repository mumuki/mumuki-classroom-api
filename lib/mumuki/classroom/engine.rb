module Mumuki
  module Classroom
    class Engine < ::Rails::Engine
      endpoint Sinatra::Application.new
      config.generators.api_only = true
    end
  end
end
