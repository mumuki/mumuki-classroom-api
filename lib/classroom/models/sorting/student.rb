module Sorting
  module Student
    class ByName < SortBy
      def self.order_by(ordering)
        {'last_name': ordering,
         'first_name': ordering}
      end
    end

    class ByProgress < SortBy
      extend WithTotalStatsPipeline

      def self.order_by(ordering)
        {'stats.total': ordering,
         'stats.failed': !ordering,
         'stats.passed_with_warnings': !ordering,
         'stats.passed': !ordering,
         'last_name': ordering,
         'first_name': ordering}
      end
    end

    class BySignupDate < SortBy
      def self.order_by(ordering)
        {'created_at': !ordering,
         'last_name': ordering,
         'first_name': ordering}
      end
    end

    class ByLastSubmissionDate < SortBy
      def self.order_by(ordering)
        {'last_assignment.submission.created_at': !ordering,
         'last_name': ordering,
         'first_name': ordering}
      end
    end
  end
end
