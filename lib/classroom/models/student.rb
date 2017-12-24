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
  field :stats, type: Hash
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  field :detached, type: Mongoid::Boolean
  field :detached_at, type: Time
  embeds_one :last_assignment

  create_index({organization: 1, course: 1, uid: 1}, {unique: true})
  create_index({organization: 1, uid: 1})
  create_index({'last_assignment.guide.slug': 1, 'last_assignment.exercise.eid': 1}, {name: 'ExBibIdIndex'})
  create_index({first_name: 'text', last_name: 'text', email: 'text'})

  def course_name
    course.to_mumukit_slug.course
  end

  def destroy_cascade!
    GuideProgress.destroy_all_by!(sub_student_query uid)
    Assignment.destroy_all_by!(sub_student_query uid)
    Guide.delete_if_has_no_progress(organization, course)
    destroy!
  end

  def update_all_stats
    all_stats = Assignment.stats_by(sub_student_query uid)
    update_attributes!(stats: all_stats)
  end

  def sub_student_query(uid)
    {'organization': organization, 'course': course, 'student.uid': uid}
  end

  def detach!
    update_attributes! detached: true, detached_at: Time.now
    Assignment.detach_all_by! sub_student_query(uid)
    GuideProgress.detach_all_by! sub_student_query(uid)
  end

  def attach!
    unset :detached, :detached_at
    Assignment.attach_all_by! sub_student_query(uid)
    GuideProgress.attach_all_by! sub_student_query(uid)
  end

  def update_last_assignment_for
    update_attributes!(last_assignment: GuideProgress.last_assignment_by(sub_student_query uid))
  end

  class << self
    def report(criteria, &block)
      where(criteria).select(&block).as_json(only: [:first_name, :last_name, :email, :created_at, :detached_at])
    end

    def update_all_stats(options)
      where(options).each(&:update_all_stats)
    end

    def last_updated_student_by(query)
      where(query).order_by(updated_at: :desc).first
    end

    def ensure_not_exists!(query)
      raise Classroom::StudentExistsError, 'Student already exist' if Student.where(query).exists?
    end
  end

end

class Classroom::StudentExistsError < Exception
end

