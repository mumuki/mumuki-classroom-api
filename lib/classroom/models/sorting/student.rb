module Sorting
  module Student
    module ByName
      def self.order_by(ordering)
        order = ordering.value
        {'last_name': order,
         'first_name': order}
      end
    end

    module ByProgress
      def self.pipeline
        [
          {
            '$addFields': {
              'stats.total': {
                '$sum': %w($stats.passed $stats.passed_with_warnings $stats.failed)
              }
            }
          }
        ]
      end

      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'stats.total': order,
         'stats.failed': revert,
         'stats.passed_with_warnings': revert,
         'stats.passed': revert,
         'last_name': order,
         'first_name': order}
      end
    end

    module BySignupDate
      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'created_at': revert,
         'last_name': order,
         'first_name': order}
      end
    end

    module ByLastSubmissionDate
      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'last_assignment.submission.created_at': revert,
         'last_name': order,
         'first_name': order}
      end
    end
  end
end
