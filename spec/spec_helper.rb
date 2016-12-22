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
  c.client_id = 'foo'
  c.client_secret = Base64.encode64 'bar'
  c.daybreak_name = 'test'
end

Rspec.configure do |config|
 config.after(:each) do
   FileUtils.rm ["#{Mumukit::Auth.config.daybreak_name}.db"], force: true
  end
end

Classroom::Database.connect! 'example'

def build_auth_header(permissions_string, sub='github|user123456')
  Mumukit::Auth::Store.set!(sub, { teacher: permissions_string })
  encoded_token = JWT.encode(
      {aud: Mumukit::Auth.config.client_id,
       sub: sub},
      Mumukit::Auth::Token.decoded_secret)
  'dummy token ' + encoded_token
end

def app
  Sinatra::Application
end

