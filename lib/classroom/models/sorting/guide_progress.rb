module Sorting::GuideProgress
  def self.from(sort_by, ordering)
    order = "#{Criteria.name}::#{ordering.to_s.camelize}".constantize
    "#{name}::By#{sort_by.to_s.camelize}".constantize.order_by order
  end

  module ByName
    def self.order_by(ordering)
      order = ordering.value
      {'student.last_name': order,
       'student.first_name': order}
    end
  end

  module ByMessages
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
