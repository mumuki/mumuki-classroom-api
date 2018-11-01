# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

Mumuki::Classroom.create_indexes!
