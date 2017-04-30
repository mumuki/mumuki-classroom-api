source 'https://rubygems.org'

gem 'rake'

gem 'sinatra'
gem 'sinatra-cross_origin', '~> 0.3.1'

gem 'mongo', '~> 2.1'
gem 'mongoid', '~> 6.1'
gem 'bson_ext'

gem 'bunny'

gem 'mumukit-core', '~> 1.0'
gem 'mumukit-nuntius', '~> 5.0'

gem 'mumukit-auth', '~> 7.0'
gem 'mumukit-service', '~> 3.0'
gem 'mumukit-login', '~> 3.0'
gem 'mumukit-platform', '~> 0.1'

gem 'mumukit-inspection', '~> 1.0'

gem 'sinatra-contrib'

group :test do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-byebug' unless Gem.win_platform?
  gem 'pry-stack_explorer'
  gem 'binding_of_caller'

  gem 'rspec', '~> 2.99'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'codeclimate-test-reporter', require: nil
end
