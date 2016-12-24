module Classroom::Collection::CourseStudents

  extend Mumukit::Service::Collection

  def self.find_by_uid!(uid)
    find_projection(student_key uid).sort(_id: -1)
      .first
      .tap { |it| validate_presence student_key(uid), it }
      .try { |it| wrap it }
  end

  def self.update!(data)
    update_one(
      key(data[:course_slug], data[:uid]),
      { '$set': { 'student.first_name': data[:first_name], 'student.last_name': data[:last_name] }}
    )
  end

  def self.create!(user, course_slug)
    course = course_slug.to_mumukit_slug.course
    ensure_new! user[:uid], course_slug
    Classroom::Collection::Courses.ensure_exist! course_slug
    Classroom::Collection::Students.for(course).ensure_new! user[:uid]
    json = { student: user, course: {slug: course_slug}}
    Classroom::Collection::CourseStudents.insert! json.wrap_json
    Classroom::Collection::Students.for(course).insert! user.wrap_json
  end

  def self.ensure_new!(uid, course_slug)
    raise Classroom::CourseStudentExistsError, "Student already exist" if any?(key course_slug, uid)
  end

  def self.ensure_exist!(uid, course_slug)
    raise Classroom::CourseStudentNotExistsError, "#{uid} does not exist in #{course_slug}" unless any?(key course_slug, uid)
  end

  def self.student_key(uid)
    { 'student.uid': uid }
  end

  def self.course_key(slug)
    { 'course.slug': slug }
  end

  def self.key(slug, uid)
    student_key(uid).merge(course_key slug)
  end

  def self.delete_student!(course_slug, student_id)
    mongo_collection.delete_one(key course_slug, student_id)
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
