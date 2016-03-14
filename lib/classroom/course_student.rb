class Classroom::CourseStudent
  extend Classroom::WithMongo

  def self.find_by(criteria)
    course_students_collection.find(criteria).sort({ _id: -1 }).projection(_id: 0).first || (raise Classroom::CourseStudentNotExistsError, "Unknown course student #{criteria}")
  end

  def self.first
    course_students_collection.find.projection(_id: 0).first
  end

  def self.count
    course_students_collection.count
  end

  def self.insert!(course_student_json)
    course_students_collection.insert_one(course_student_json)
  end

end

class Classroom::CourseStudentNotExistsError < StandardError
end
