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

  config.before(:each) do
    if RSpec.current_example.metadata[:organization_workspace]
      create(:organization, name: RSpec.current_example.metadata[:organization_workspace]).switch!
    end
  end

  config.after(:each) do
    Mumukit::Platform::Organization.leave! if RSpec.current_example.metadata[:organization_workspace]
  end

  config.full_backtrace = true if ENV['RSPEC_FULL_BACKTRACE']
end

require 'base64'
Mumukit::Auth.configure do |c|
  c.clients.default = {id: 'test-client', secret: 'thisIsATestSecret'}
end

def build_auth_header(permissions, sub='github|123456')
  Mumukit::Platform::User.upsert_permissions! sub, {owner: permissions}
  Mumukit::Auth::Token.encode sub, {}
end

def app
  Mumuki::Classroom::App
end

SimpleCov.start
