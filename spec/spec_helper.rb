require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'factory_girl'
require 'rack/test'
require 'mumukit/auth'

require_relative '../lib/classroom'

ENV['RACK_ENV'] = 'test'

Mongo::Logger.logger.level = ::Logger::INFO

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods
end

RSpec::Matchers.define :json_eq do |expected_json_hash|
  match do |actual_json|
    expected_json_hash.with_indifferent_access == ActiveSupport::JSON.decode(actual_json)
  end
end

require 'base64'
Mumukit::Auth.configure do |c|
  c.client_id = 'foo'
  c.client_secret = Base64.encode64 'bar'
end

Classroom::Database.tenant = 'test'

def build_auth_header(permissions_string)
  Mumukit::Auth::Token.encode_dummy_auth_header(bibliotheca: {permissions: permissions_string})
end