source 'https://rubygems.org'

gem 'rake'

gem 'sinatra', '~> 1.4'
gem 'sinatra-contrib', '~> 1.4'
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

gem 'mumukit-content-type',
    git: 'https://github.com/mumuki/mumukit-content-type',
    require: 'mumukit/content_type',
    ref: 'v1.1.0-mumuki-rouge'
gem 'rouge',
    git: 'https://github.com/mumuki/rouge',
    ref: '5a8db3387f3a67232569969cd3da40ee04eb9dc3'

gem 'activemodel', '~> 5.0'
gem 'activesupport', '~> 5.0'

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
