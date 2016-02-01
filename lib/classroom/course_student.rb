class Classroom::CourseStudent
  extend Classroom::WithMongo

  def self.count
    courses_students_collection.count
  end
end