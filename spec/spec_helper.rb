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

def spec_helper_as_json(obj, options = {})
  new_options = options.with_indifferent_access
  new_options['only'] = [*new_options['only']].map &:to_s if new_options['only']
  new_options['except'] = [*new_options['except']].map &:to_s if new_options['except']
  if obj.instance_of? String
    JSON.parse(obj).as_json new_options
  else
    JSON.parse(JSON.unparse obj).as_json new_options
  end
end

RSpec::Matchers.define :json_like do |expected, options={}|
  match do |actual|
    spec_helper_as_json(actual, options) == spec_helper_as_json(expected, options)
  end

  failure_message_for_should do |actual|
    <<-EOS
    expected: #{spec_helper_as_json(expected, options)} (#{expected.class})
         got: #{spec_helper_as_json(actual, options)} (#{actual.class})
    EOS
  end

  failure_message_for_should_not do |actual|
    <<-EOS
    expected: value != #{spec_helper_as_json(expected, options)} (#{expected.class})
         got:          #{spec_helper_as_json(actual, options)} (#{actual.class})
    EOS
  end
end

RSpec::Matchers.define :json_eq do |expected|
  match do |actual|
    spec_helper_as_json(actual) == spec_helper_as_json(expected)
  end

  failure_message_for_should do |actual|
    <<-EOS
    expected: #{spec_helper_as_json(expected)} (#{expected.class})
         got: #{spec_helper_as_json(actual)} (#{actual.class})
    EOS
  end

  failure_message_for_should_not do |actual|
    <<-EOS
    expected: value != #{spec_helper_as_json(expected)} (#{expected.class})
         got:          #{spec_helper_as_json(actual)} (#{actual.class})
    EOS
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

