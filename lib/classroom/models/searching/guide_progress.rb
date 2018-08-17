module Searching
  module GuideProgress
    class NotFailedAssignments < BaseFilter

      def pipeline
        [
          {
            '$addFields':
              {'stats.not_failed': {'$sum': %w($stats.passed $stats.passed_with_warnings)}}
          },
          {
            '$match':
              {'stats.not_failed': {'$gte': @query_param.to_i}}
          }
        ]
      end
    end

    class PassedAssignments < BaseFilter
      def query
        {'stats.passed': {'$gte': @query_param.to_i}}
      end
    end
  end
end
