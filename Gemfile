source 'https://rubygems.org'

gem 'rake'

gem 'sinatra', '~> 1.4'
gem 'sinatra-contrib', '~> 1.4'
gem 'sinatra-cross_origin', '~> 0.3.1'

gem 'mongo', '~> 2.1'
gem 'mongoid', '~> 6.1'
gem 'bson_ext'

gem 'bunny'

gem 'mumukit-core', '~> 1.1'
gem 'mumukit-nuntius', '~> 6.0'

gem 'mumukit-auth', '~> 7.0'
gem 'mumukit-service', '~> 3.0'

gem 'mumukit-platform', github: 'mumuki/mumukit-platform', branch: 'feature-unified-platform-model'
gem 'mumukit-login', github: 'mumuki/mumukit-login', branch: 'feature-unified-platform-model'

gem 'mumukit-inspection', '~> 1.0'
gem 'mumukit-content-type', '~> 1.3'

gem 'activemodel', '~> 5.0'
gem 'activesupport', '~> 5.0'

group :test, :development do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-byebug' unless Gem.win_platform?
  gem 'pry-stack_explorer'
  gem 'binding_of_caller'

  gem 'sinatra-rake-routes'
  gem 'rspec', '~> 2.99'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'codeclimate-test-reporter', require: nil
end
