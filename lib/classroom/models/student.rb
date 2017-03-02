class Student

  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :name, type: String
  field :email, type: String
  field :image_url, type: String
  field :social_id, type: String
  field :last_assignment, type: Hash
  field :stats, type: Hash
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  field :detached, type: Mongoid::Boolean
  field :detached_at, type: Time

  create_index({organization: 1, course: 1, uid: 1}, {unique: true})

  def self.report(criteria, &block)
    where(criteria).select(&block).as_json(only: [:first_name, :last_name, :email, :created_at, :detached_at])
  end

  def self.update_all_stats(options)
    where(options).each(&:update_all_stats)
  end

  def self.find_by_uid!(uid)
    find_by!(uid: uid)
  end

  def course_name
    course.to_mumukit_slug.course
  end

  def destroy_cascade!
    student = {'student.uid': uid}
    Classroom::Collection::CourseStudents.for(organization).delete_many(student.merge('course.slug': course, organization: organization))
    Classroom::Collection::GuideStudentsProgress.for(organization, course_name).delete_many(student.merge(organization: organization))
    Assignment.destroy_all_by!(sub_student_query uid)
    Guide.delete_if_has_no_progress(organization, course)
    destroy!
  end

  def update_all_stats
    all_stats = Classroom::Collection::ExerciseStudentProgress.for(organization, course_name).all_stats(uid)
    update_attributes!(stats: all_stats)
  end

  def sub_student_query(uid)
    {'organization': organization, 'course': course, 'student.uid': uid}
  end

  def detach!
    update_attributes! detached: true, detached_at: Time.now
    Assignment.detach_all_by! sub_student_query(uid)
    Classroom::Collection::GuideStudentsProgress.for(organization, course_name).detach_student! uid
  end

  def attach!
    unset :detached, :detached_at
    Assignment.attach_all_by! sub_student_query(uid)
    Classroom::Collection::GuideStudentsProgress.for(organization, course_name).attach_student! uid
  end

  def update_last_assignment_for
    last_assignment = Classroom::Collection::GuideStudentsProgress.for(organization, course_name).last_assignment_for(uid)
    update_attributes!(last_assignment: last_assignment)
  end

end
