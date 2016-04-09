module Classroom
end

require 'active_support/all'
require 'mongo'
require 'bunny'
require_relative './classroom/with_mongo'
require_relative './classroom/database'
require_relative './classroom/rabbit'
require_relative './classroom/course'
require_relative './classroom/course_student'
require_relative './classroom/guide_progress'
require_relative './classroom/comment'
require_relative './classroom/follower'

