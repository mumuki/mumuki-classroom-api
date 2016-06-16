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

Classroom::Database.organization = 'example'

def build_auth_header(permissions_string, sub='github|user123456')
  metadata = {classroom: {permissions: permissions_string}}

  encoded_token = JWT.encode(
      {aud: Mumukit::Auth.config.client_id,
       sub: sub,
       app_metadata: metadata},
      Mumukit::Auth::Token.decoded_secret)
  'dummy token ' + encoded_token
end
