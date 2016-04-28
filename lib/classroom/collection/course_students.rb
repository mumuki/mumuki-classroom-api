module Classroom::Collection::CourseStudents

  extend Mumukit::Service::Collection

  def self.first
    order_by({}, { _id: -1 })
  end

  private

  def self.mongo_collection_name
    :course_students
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::JsonWrapper.new(it)
  end

end

class Classroom::CourseStudentNotExistsError < StandardError
end
