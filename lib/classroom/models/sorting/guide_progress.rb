module Sorting
  module GuideProgress
    module ByName
      def self.order_by(ordering)
        order = ordering.value
        {'student.last_name': order,
         'student.first_name': order}
      end
    end

    module ByMessages
      def self.lookup
        {
          from: 'notifications',
          
        }
      end

      def self.order_by(ordering)
        order = ordering.value
        {'student.last_name': order,
         'student.first_name': order}
      end
    end

    module ByProgress
      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'stats.passed': revert,
         'stats.passed_with_warnings': revert,
         'stats.failed': revert,
         'last_name': order,
         'first_name': order}
      end
    end

    module ByLastSubmissionDate
      def self.order_by(ordering)
        order = ordering.value
        {'updated_at': order,
         'last_name': order,
         'first_name': order}
      end
    end
  end
end
