ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'
require 'codeclimate-test-reporter'
require 'mumukit/core/rspec'
require 'factory_bot_rails'

ActiveRecord::Migration.maintain_test_schema!

require 'rack/test'
require 'mumukit/auth'
require 'mumukit/content_type'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
    config.include Rack::Test::Methods
    config.include FactoryBot::Syntax::Methods
    config.infer_spec_type_from_file_location!
end

SimpleCov.start


ENV['RACK_ENV'] = 'test'

require 'byebug'
require 'codeclimate-test-reporter'
SimpleCov.start

require 'factory_girl'
require 'rack/test'

require_relative '../lib/classroom'
require_relative '../app/routes'

Mongo::Logger.logger.level = ::Logger::INFO

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods

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

