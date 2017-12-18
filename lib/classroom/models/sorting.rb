module Sorting
  module Student
    def self.from(sort_by, ordering)
      order = "Criteria::#{ordering.to_s.camelize}".constantize
      "#{name}::#{sort_by.to_s.camelize}".constantize.order_by order
    end

    module ByName
      def self.order_by(ordering)
        order = ordering.value
        {'last_name': order,
         'first_name': order}
      end
    end

    module ByProgress
      def self.order_by(ordering)
        order = ordering.value
        revert = ordering.negated.value
        {'stats.failed': revert,
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
        {'updated_at': order,
         'last_name': order,
         'first_name': order}
      end
    end

  end
end

module Criteria
  module Asc
    def self.value
      :asc
    end

    def self.negated
      Desc
    end
  end

  module Desc
    def self.value
      :desc
    end

    def self.negated
      Asc
    end
  end
end
