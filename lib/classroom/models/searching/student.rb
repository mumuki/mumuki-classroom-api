module Searching
  module Student
    class StudentFilter < SimpleFilter

    end

    def self.default_filter
      StudentFilter
    end
  end
end
