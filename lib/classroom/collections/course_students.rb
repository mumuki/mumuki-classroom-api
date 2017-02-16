class Classroom::Collection::CourseStudents < Classroom::Collection::OrganizationCollection

  include Mumukit::Service::Collection

  def find_by_uid!(uid)
    find_projection(student_key uid).sort(_id: -1)
      .first
      .tap { |it| validate_presence student_key(uid), it }
      .try { |it| wrap it }
  end

  def find_by_uid(uid)
    find_projection(student_key uid).sort(_id: -1)
      .first
      .try { |it| wrap it }
  end

  def update_student!(sub_student)
    mongo_collection.update_many({'student.uid': sub_student[:'student.uid']}, {'$set': sub_student})
  end

  def self.create!(user, course_uid)
    course = course_uid.to_mumukit_slug.course
    ensure_new! user[:uid], course_uid
    Classroom::Collection::Courses.ensure_exist! course_uid
    Classroom::Collection::Students.for(course).ensure_new! user[:uid]
    json = {student: user, course: {uid: course_uid}}
    Classroom::Collection::CourseStudents.insert! json.wrap_json
    Classroom::Collection::Students.for(course).insert! user.wrap_json
  end

  def ensure_new!(uid, course_slug)
    raise Classroom::CourseStudentExistsError, "Student already exist" if any?(key course_slug, uid)
  end

  def ensure_exist!(uid, course_slug)
    raise Classroom::CourseStudentNotExistsError, "#{uid} does not exist in #{course_slug}" unless any?(key course_slug, uid)
  end

  def student_key(uid)
    query 'student.uid': uid
  end

  def course_key(uid)
    query 'course.uid': uid
  end

  def key(course_uid, student_uid)
    student_key(student_uid).merge(course_key course_uid)
  end

  def delete_student!(course_uid, student_uid)
    mongo_collection.delete_one(key course_uid, student_uid)
  end

  private

  def pk
    super.merge 'student.uid': 1, 'course.uid': 1
  end
end

class Classroom::CourseStudentExistsError < StandardError
end

class Classroom::CourseStudentNotExistsError < StandardError
end
