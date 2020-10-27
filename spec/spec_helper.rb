ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

require File.expand_path("../dummy/config/environment.rb", __FILE__)

require 'rspec/rails'
require 'codeclimate-test-reporter'
require 'mumukit/core/rspec'
require 'rack/test'
require 'factory_bot_rails'
require 'byebug'

require 'mumuki/domain/factories'
require_relative '../lib/mumuki/classroom'
require_relative './spec_workspace'

require_relative 'factories/student_factory'

ActiveRecord::Migration.maintain_test_schema!

Mongo::Logger.logger.level = ::Logger::INFO

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.use_transactional_fixtures = true
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    Mongoid::Clients.default.collections.each(&:delete_many)
  end
  initialize_workspaces config
end

require 'base64'
Mumukit::Auth.configure do |c|
  c.clients.default = {id: 'test-client', secret: 'thisIsATestSecret'}
end

def build_auth_header(permissions, sub = 'github|123456')
  user = User.where(uid: sub).first_or_create! permissions: Mumukit::Auth::Permissions.parse(owner: permissions)
  Mumukit::Auth::Token.encode user.uid, {}
end

def app
  Mumuki::Classroom::App
end

SimpleCov.start
