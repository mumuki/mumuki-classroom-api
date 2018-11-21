# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Create mongo indexes
Mumuki::Classroom.create_indexes!
