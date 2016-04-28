module Classroom
end

require 'mumukit/service'
require 'active_support/all'

require_relative './classroom/with_mongo'
require_relative './classroom/database'
require_relative './classroom/json_wrapper'
require_relative './classroom/follower'
require_relative './classroom/collection'
