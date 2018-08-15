module Sorting
  module Student
    class ByName < SortBy
      def self.pipeline
        [{'$addFields': {
          'last_name': {'$toLower': '$last_name'},
          'first_name': {'$toLower': '$first_name'}
        }}]
      end

      def self.order_by(ordering)
        {'last_name': ordering,
         'first_name': ordering}
      end
    end

    class ByProgress < TotalStatsSortBy

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
