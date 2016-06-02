module Classroom::Collection::CourseStudents

  extend Mumukit::Service::Collection

  def self.find_by_social_id!(social_id)
    args = { 'student.social_id' => social_id }
    find_projection(args).sort(:_id => -1)
      .first
      .tap { |it| validate_presence(args, it) }
      .try { |it| wrap(it) }
  end

  def self.ensure_new!(social_id, course_slug)
    raise Classroom::CourseStudentExistsError, "Student already exist" if any?('student.social_id' => social_id, 'course.slug' => course_slug)
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

class Classroom::CourseStudentExistsError < StandardError
end
