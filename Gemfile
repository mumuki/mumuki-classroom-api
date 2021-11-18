source 'https://rubygems.org'

gemspec

ruby '~> 2.6'

gem 'puma', '~> 3.7'

group :test do
  gem 'rspec-rails', '~> 3.6'
  gem 'factory_bot_rails', '~> 5.0'
  gem 'rake', '~> 12.3.0'
  gem 'faker', '~> 2.2'
  gem 'capybara', '~> 2.3.0'
  gem 'codeclimate-test-reporter', require: nil
  gem 'rack-test'
end

group :development do
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-byebug' unless Gem.win_platform?
  gem 'pry-stack_explorer'
  gem 'binding_of_caller'
  gem 'web-console'
end


gem 'mumukit-auth', github: 'mumuki/mumukit-auth', branch: 'cc73f15069b90b28fa6db5ef694d7414e292fc2f'
gem 'mumuki-domain', github: 'mumuki/mumuki-domain', branch: 'feature-permissions-compact'
