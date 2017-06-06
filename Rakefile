Dir.glob('lib/tasks/*.rake').each { |r| import r }

require_relative './lib/classroom'

Mongo::Logger.logger = ::Logger.new(File.join 'logs', 'rake.mongo.log')
Mongo::Logger.logger.level = ::Logger::INFO

task :routes do
  require_relative './app/routes'
  require 'sinatra-rake-routes'
  # Tell SinatraRakeRoutes what your Sinatra::Base application class is called:
  SinatraRakeRoutes.set_app_class(Sinatra::Application)
end

require 'sinatra-rake-routes/tasks'
