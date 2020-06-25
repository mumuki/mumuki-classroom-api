class Mumuki::Classroom::Student < Mumuki::Classroom::Document
  include CourseMember

  field :personal_id, type: String
  field :stats, type: Hash
  field :detached, type: Mongoid::Boolean
  field :detached_at, type: Time
  embeds_one :last_assignment, class_name: 'Mumuki::Classroom::LastAssignment'

  create_index({organization: 1, uid: 1})
  create_index({'last_assignment.guide.slug': 1, 'last_assignment.exercise.eid': 1}, {name: 'ExBibIdIndex'})
  create_index({first_name: 'text', last_name: 'text', email: 'text', personal_id: 'text'})

  def course_name
    course.to_mumukit_slug.course
  end

  def destroy_cascade!
    Mumuki::Classroom::GuideProgress.destroy_all_by!(sub_student_query uid)
    Mumuki::Classroom::Assignment.destroy_all_by!(sub_student_query uid)
    destroy!
  end

  def update_all_stats
    all_stats = Mumuki::Classroom::Assignment.stats_by(sub_student_query uid)
    update_attributes!(stats: all_stats)
  end

  def sub_student_query(uid)
    {'organization': organization, 'course': course, 'student.uid': uid}
  end

  def detach!
    update_attributes! detached: true, detached_at: Time.now
    Mumuki::Classroom::Assignment.detach_all_by! sub_student_query(uid)
    Mumuki::Classroom::GuideProgress.detach_all_by! sub_student_query(uid)
  end

  def attach!
    unset :detached, :detached_at
    Mumuki::Classroom::Assignment.attach_all_by! sub_student_query(uid)
    Mumuki::Classroom::GuideProgress.attach_all_by! sub_student_query(uid)
  end

  def transfer_to!(organization, course)
    Mumuki::Classroom::Assignment.transfer_all_by! sub_student_query(uid), organization, course
    Mumuki::Classroom::GuideProgress.transfer_all_by! sub_student_query(uid), organization, course
    update_attributes! organization: organization, course: course
  end

  def update_last_assignment_for
    update_attributes!(last_assignment: Mumuki::Classroom::GuideProgress.last_assignment_by(sub_student_query uid))
  end

  def as_user
    User.whitelist_attributes self.as_json.merge validated_first_name: first_name, validated_last_name: last_name
  end

  class << self
    def report(criteria, &block)
      where(criteria).select(&block).as_json(only: [:first_name, :last_name, :email, :created_at, :detached_at])
    end

    def update_all_stats(options)
      where(options).each(&:update_all_stats)
    end

    def last_updated_student_by(query)
      where(query).ne(detached: true).order_by(updated_at: :desc).first
    end

    def detach_all_by!(uids, query)
      where(query).in(uid: uids).update_all(detached: true, detached_at: Time.now)
      criteria = query.merge('student.uid': {'$in': uids})
      Mumuki::Classroom::Assignment.detach_all_by! criteria
      Mumuki::Classroom::GuideProgress.detach_all_by! criteria
    end

    def attach_all_by!(uids, query)
      where(query).in(uid: uids).unset(:detached, :detached_at)
      criteria = query.merge('student.uid': {'$in': uids})
      Mumuki::Classroom::Assignment.attach_all_by! criteria
      Mumuki::Classroom::GuideProgress.attach_all_by! criteria
    end

    def uid_field
      :uid
    end
  end

end

