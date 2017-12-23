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
      def self.add_fields
        {
          'stats.total': {
            '$sum': %w($stats.passed $stats.passed_with_warnings $stats.failed)
          }
        }
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
        {'created_at': order,
         'last_name': order,
         'first_name': order}
      end
    end

    module ByLastSubmissionDate
      def self.order_by(ordering)
        order = ordering.value
        {'last_assignment.submission.created_at': order,
         'last_name': order,
         'first_name': order}
      end
    end
  end
end
