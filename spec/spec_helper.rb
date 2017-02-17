require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'factory_girl'
require 'rack/test'

require_relative '../lib/classroom'
require_relative '../app/routes'

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

RSpec::Matchers.define :json_like do |expected, options={}|
  except = options[:except] || []
  match do |actual|
    actual.as_json.with_indifferent_access.except(except) == expected.as_json.with_indifferent_access
  end

  failure_message_for_should do |actual|
    <<-EOS
    expected: #{expected.as_json} (#{expected.class})
         got: #{actual.as_json} (#{actual.class})
    EOS
  end

  failure_message_for_should_not do |actual|
    <<-EOS
    expected: value != #{expected.as_json} (#{expected.class})
         got:          #{actual.as_json} (#{actual.class})
    EOS
  end
end

require 'base64'
Mumukit::Auth.configure do |c|
  c.clients.default = {id: 'test-client', secret: 'thisIsATestSecret'}
end

Classroom::Database.connect!

def build_mumuki_auth_header(permissions, sub='github|user123456')
  Classroom::Collection::Users.upsert_permissions! sub, {owner: permissions}
  Mumukit::Auth::Token.encode sub, {}
end

def build_auth_header(permissions, sub='github|user123456')
  Classroom::Collection::Users.upsert_permissions! sub, {owner: permissions}
  Mumukit::Auth::Token.encode sub, {}
end

def app
  Sinatra::Application
end

