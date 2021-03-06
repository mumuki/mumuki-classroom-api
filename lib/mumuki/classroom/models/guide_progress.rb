class Mumuki::Classroom::GuideProgress < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  demodulized_model_name

  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  field :stats, type: Hash
  field :guide, type: Hash

  embeds_one :student, class_name: 'Mumuki::Classroom::Student'
  embeds_one :last_assignment

  create_index({'organization': 1, 'course': 1, 'student.uid': 1})
  create_index({'organization': 1, 'course': 1, 'guide.slug': 1, 'student.uid': 1})
  create_index({'guide.slug': 1, 'last_assignment.exercise.eid': 1}, {name: 'ExBibIdIndex'})
  create_index({'student.first_name': 'text', 'student.last_name': 'text', 'student.email': 'text'})

  def slug
    guide[:slug]
  end

  class << self
    def detach_all_by!(query)
      where(query).set(detached: true)
    end

    def attach_all_by!(query)
      where(query).unset(:detached)
    end

    def destroy_all_by!(query)
      where(query).destroy
    end

    def transfer_all_by!(query, new_organization, new_course)
      where(query).set(organization: new_organization, course: new_course)
    end

    def last_assignment_by(query)
      where(query).order_by('last_assignment.submission.created_at': :desc).first.try do |it|
        Mumuki::Classroom::LastAssignment.new(guide: it.guide,
                                              exercise: it.last_assignment.exercise,
                                              submission: {
                                                sid: it.last_assignment.submission.sid,
                                                status: it.last_assignment.submission.status,
                                                created_at: it.last_assignment.submission.created_at,
                                              })
      end
    end

    def uid_field
      'student.uid'.to_sym
    end

    def progresses_for(progress_item, student)
      where(organization: progress_item.organization, course: student.course, slug: progress_item.content.slug, 'student.uid': student.uid)
    end
  end

end
