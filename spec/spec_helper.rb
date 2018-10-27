ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

APP_PATH = File.expand_path('../../spec/dummy/config/application', __FILE__)
require File.expand_path("../dummy/config/environment.rb", __FILE__)

require 'rspec/rails'
require 'codeclimate-test-reporter'
require 'mumukit/core/rspec'
require 'rack/test'
require 'factory_girl'
require 'factory_girl_rails'
require 'byebug'

require_relative '../lib/mumuki/classroom'

ActiveRecord::Migration.maintain_test_schema!

Mongo::Logger.logger.level = ::Logger::INFO

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.use_transactional_fixtures = true
  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    Mongoid::Clients.default.collections.each(&:delete_many)
  end
end

require 'base64'
Mumukit::Auth.configure do |c|
  c.clients.default = {id: 'test-client', secret: 'thisIsATestSecret'}
end

def build_mumuki_auth_header(permissions, sub='github|123456')
  User.upsert_permissions! sub, {owner: permissions}
  Mumukit::Auth::Token.encode sub, {}
end

def build_auth_header(permissions, sub='github|123456')
  User.upsert_permissions! sub, {owner: permissions}
  Mumukit::Auth::Token.encode sub, {}
end

def app
  Sinatra::Application
end

SimpleCov.start
