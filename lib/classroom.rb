module Classroom
end

require 'mumukit/core'
require 'mumukit/service'
require 'mumukit/inspection'
require 'mumukit/nuntius'

require 'rest-client'

require_relative './class'
require_relative './atheneum'
require_relative './consumer'

require_relative './classroom/database'
require_relative './classroom/json_wrapper'

require_relative './classroom/collections'
require_relative './classroom/documents'

require_relative './classroom/submission'
require_relative './classroom/failed_submission'

