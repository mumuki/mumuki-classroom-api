$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mumuki/classroom/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mumuki-classroom"
  s.version     = Mumuki::Classroom::VERSION
  s.authors     = ["Franco Bulgarelli"]
  s.email       = ["franco@mumuki.org"]
  s.homepage    = "https://mumuki.org"
  s.summary     = "Teacher tools for Mumuki"
  s.description = "Teacher tools for Mumuki"
  s.license     = "GPL"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.6"

  s.add_dependency 'sinatra', '~> 2.0'
  s.add_dependency 'sinatra-contrib', '~> 2.0'
  s.add_dependency 'sinatra-cross_origin', '~> 0.3.1'

  s.add_dependency 'mumuki-domain', '~> 6.7.2'
  s.add_dependency 'mumukit-login', '~> 6.1'
  s.add_dependency 'mumukit-nuntius', '~> 6.2'

  s.add_dependency 'mongo', '2.4.1'
  s.add_dependency 'mongoid', '6.1.0'
  s.add_dependency 'bson_ext', '1.5.1'

  s.add_dependency 'rack', '~> 2.0'
  s.add_development_dependency 'pg', '~> 0.18.0'
end
