module Searching
  module GuideProgress
    class PassedAssignments
      def self.query_for(param)
        {'stats.total_passed': {'$gte': param.to_i}}
      end

      def self.pipeline
        [{'$addFields':
           {'stats.total_passed': {'$sum': %w($stats.passed $stats.passed_with_warnings)}}
        }]
      end
    end
  end
end
