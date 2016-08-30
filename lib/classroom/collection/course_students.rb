module Classroom::Collection::CourseStudents

  extend Mumukit::Service::Collection

  def self.find_by_social_id!(social_id)
    args = { 'student.social_id' => social_id }
    find_projection(args).sort(:_id => -1)
      .first
      .tap { |it| validate_presence(args, it) }
      .try { |it| wrap(it) }
  end

  def self.update!(data)
    query = {'student.social_id' => data[:social_id], 'course.slug' => data[:course_slug]}
    update_one(query, { '$set' => { 'student.first_name' => data[:first_name], 'student.last_name' => data[:last_name] }})
  end

  def self.ensure_new!(social_id, course_slug)
    raise Classroom::CourseStudentExistsError, "Student already exist" if any?('student.social_id' => social_id, 'course.slug' => course_slug)
  end

  def self.ensure_exist!(social_id, slug)
    raise Classroom::CourseStudentNotExistsError, "#{social_id} does not exist in #{slug}" unless any?('student.social_id' => social_id, 'course.slug' => slug)
  end

  def self.delete_student!(course_slug, student_id)
    mongo_collection.delete_one('course.slug' => course_slug, 'student.social_id' => student_id)
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

class Classroom::CourseStudentNotExistsError < StandardError
end
