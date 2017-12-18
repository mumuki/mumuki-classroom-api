module Sorting
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

require_relative './sorting/student'
require_relative './sorting/guide_progress'
