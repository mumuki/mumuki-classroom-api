module Searching
  module GuideProgress
    module QueryOperands
      include Searching::QueryOperands

      def more_than(value)
        {'$gte': value}
      end

      def less_than(value)
        {'$lte': value}
      end

      def close_to(value)
        more_than(value - 1).merge(less_than value + 1)
      end

      def default_query_operand
        :more_than
      end
    end

    class NotFailedAssignments < NumericFilter
      include Searching::GuideProgress::QueryOperands

      def pipeline
        [
          {
            '$addFields':
              {'stats.not_failed': {'$sum': %w($stats.passed $stats.passed_with_warnings)}}
          },
          {
            '$match':
              {'stats.not_failed': current_query_operand }
          }
        ]
      end
    end

    class PassedAssignments < NumericFilter
      include Searching::GuideProgress::QueryOperands

      def query
        {'stats.passed': current_query_operand}
      end
    end

    class TotalAssignments < NumericFilter
      include Searching::GuideProgress::QueryOperands

      def pipeline
        [
          {
            '$addFields': {'stats.total': {'$sum': %w($stats.passed $stats.passed_with_warnings $stats.failed)}}
          },
          {
            '$match': {'stats.total': current_query_operand }
          }
        ]
      end
    end

    class SolvedAssignmentsPercentage < NumericFilter
      include Searching::GuideProgress::QueryOperands

      def pipeline
        [
          {
            '$addFields': {
              'stats.solved_percentage': {
                '$multiply': [
                  {
                    '$divide': [
                      {'$sum': %w($stats.passed $stats.passed_with_warnings)},
                      {'$sum': %w($stats.passed $stats.passed_with_warnings $stats.failed)}
                    ]
                  },
                  100
                ]
              }
            }
          },
          {
            '$match': {'stats.solved_percentage': current_query_operand }
          }
        ]
      end
    end
  end
end
