module Classroom
end

require 'active_support/all'
require 'mongo'
require_relative './mongo_collection'
require_relative './classroom/with_mongo'
require_relative './classroom/database'
require_relative './classroom/course'
require_relative './classroom/course_student'
require_relative './classroom/guide_progress'
require_relative './classroom/comment'

