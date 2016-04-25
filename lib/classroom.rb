module Classroom
end

require 'mumukit/service'
require 'active_support/all'

require_relative './classroom/with_mongo'
require_relative './classroom/database'
require_relative './classroom/course'
require_relative './classroom/course_student'
require_relative './classroom/guide_progress'
require_relative './classroom/comment'
require_relative './classroom/follower'
require_relative './classroom/failed_submission'

