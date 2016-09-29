module Classroom
end

require 'mumukit/core'
require 'mumukit/service'
require 'mumukit/inspection'
require 'rest-client'

require_relative './classroom/database'
require_relative './classroom/json_wrapper'
require_relative './classroom/collection'
require_relative './classroom/follower'
require_relative './classroom/submission'
require_relative './classroom/failed_submission'
require_relative './classroom/comments'

