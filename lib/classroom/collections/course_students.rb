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

  def create!(user, course_slug)
    ensure_new! user[:uid], course_slug
    Course.ensure_exist! organization: organization, slug: course_slug
    json = {student: user, course: {slug: course_slug}}
    Classroom::Collection::CourseStudents.for(organization).insert! json
    Student.create!(user.merge(organization: organization, course: course_slug))
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
    query 'course.slug': uid
  end

  def key(course_slug, student_uid)
    student_key(student_uid).merge(course_key course_slug)
  end

  def delete_student!(course_slug, student_uid)
    mongo_collection.delete_one(key course_slug, student_uid)
  end

  private

  def pk
    super.merge 'student.uid': 1, 'course.slug': 1
  end
end

class Classroom::CourseStudentExistsError < StandardError
end

class Classroom::CourseStudentNotExistsError < StandardError
end
