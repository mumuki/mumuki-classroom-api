module Classroom::CourseStudent
  extend Classroom::WithMongo

  class << self
    def collection_name
      'course_students'
    end

    def find_by(criteria)
      find(criteria).sort({ _id: -1 }).projection(_id: 0).first || (raise Classroom::CourseStudentNotExistsError, "Unknown course student #{criteria}")
    end

    def first
      find.projection(_id: 0).first
    end
  end
end

class Classroom::CourseStudentNotExistsError < StandardError
end
