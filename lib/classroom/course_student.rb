class Classroom::CourseStudent
  extend Classroom::WithMongo

  def self.collection_name
    'course_students'
  end

  def self.find_by(criteria)
    find(criteria).sort({ _id: -1 }).projection(_id: 0).first || (raise Classroom::CourseStudentNotExistsError, "Unknown course student #{criteria}")
  end

  def self.first
    find.projection(_id: 0).first
  end
end

class Classroom::CourseStudentNotExistsError < StandardError
end
