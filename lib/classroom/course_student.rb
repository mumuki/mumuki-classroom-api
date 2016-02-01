class Classroom::CourseStudent
  extend Classroom::WithMongo

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