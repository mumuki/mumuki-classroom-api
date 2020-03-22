source 'https://rubygems.org'

gem 'rake', '>= 12.3.3'

gem 'sinatra', '~> 1.4'
gem 'sinatra-contrib', '~> 1.4'
gem 'sinatra-cross_origin', '~> 0.3.1'

gem 'mongo', '~> 2.1'
gem 'mongoid', '~> 6.1'
gem 'bson_ext'

gem 'bunny'

gem 'mumukit-core', '~> 1.8'
gem 'mumukit-nuntius', '~> 6.1'

gem 'mumukit-auth', '~> 7.7'
gem 'mumukit-service', '~> 3.0'
gem 'mumukit-platform', '~> 1.3'
gem 'mumukit-login', '~> 5.2.0'

gem 'mumukit-inspection', '~> 1.0'
gem 'mumukit-content-type', '~> 1.8'

gem 'activemodel', '~> 5.0'
gem 'activesupport', '~> 5.0'

group :test, :development do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-byebug' unless Gem.win_platform?
  gem 'pry-stack_explorer'
  gem 'binding_of_caller'

  gem 'sinatra-rake-routes', '>= 0.0.4'
  gem 'rspec', '~> 2.99'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'codeclimate-test-reporter', require: nil
end
