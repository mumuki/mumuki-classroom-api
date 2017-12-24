module Sorting
  module Student
    class ByName < SortBy
      def self.order_by(ordering)
        order = ordering.value
        {'last_name': order,
         'first_name': order}
      end
    end

    class ByProgress < SortBy
      extend WithTotalStatsPipeline

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

    class BySignupDate < SortBy
      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'created_at': revert,
         'last_name': order,
         'first_name': order}
      end
    end

    class ByLastSubmissionDate < SortBy
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
