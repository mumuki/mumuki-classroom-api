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
  end
end
