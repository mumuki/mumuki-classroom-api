$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mumuki/classroom/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mumuki-classroom"
  s.version     = Mumuki::Classroom::VERSION
  s.authors     = ["Franco Bulgarelli"]
  s.email       = ["franco@mumuki.org"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Mumuki::Classroom."
  s.description = "TODO: Description of Mumuki::Classroom."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.6"

  s.add_development_dependency "sqlite3"
end
