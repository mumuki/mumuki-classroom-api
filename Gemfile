source 'https://rubygems.org'

gem 'rake'

gem 'sinatra', '~> 1.4', '>= 1.4.8'
gem 'sinatra-contrib', '~> 1.4', '>= 1.4.7'
gem 'sinatra-cross_origin', '~> 0.3.1'

gem 'mongo', '~> 2.1'
gem 'mongoid', '~> 6.1'
gem 'bson_ext'

gem 'bunny'

gem 'mumukit-core', '~> 1.16', '>= 1.16.0'
gem 'mumukit-nuntius', '~> 6.1', '>= 6.1.0'

gem 'mumukit-auth', '~> 7.7', '>= 7.7.0'
gem 'mumukit-service', '~> 3.0', '>= 3.0.2'
gem 'mumukit-platform', '~> 1.3', '>= 1.3.0'
gem 'mumukit-login', '~> 5.2.0'

gem 'mumukit-inspection', '~> 1.0', '>= 1.0.0'
gem 'mumukit-content-type', '~> 1.8', '>= 1.8.0'

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
  gem 'rack-test', '>= 0.6.3'
  gem 'factory_girl'
  gem 'codeclimate-test-reporter', require: nil
end
