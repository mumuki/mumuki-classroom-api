class Mumuki::Classroom::Event::ProgressTransfer::Base
  attr_reader :indicator, :source_organization

  def initialize(indicator, source_organization, destination_organization)
    @indicator = indicator
    @source_organization = source_organization
    @destination_organization = destination_organization
  end

  def execute!
    raise ActiveRecord::RecordNotFound, "Mumuki::Classroom::Student not found" unless old_student && new_student

    new_student.destroy_progress!
    destination_organization.switch!

    indicator.assignments.each do |assignment|
      # TODO what if classroom_assignment does not exist?
      transfer_sibling_for(assignment).update! organization: destination_organization.name,
                                                course: new_course,
                                                guide: guide_h
    end

    transfer_guide_progress!
    update_student!(old_student)
    update_student!(new_student)
  end

  private

  def update_student!(student)
    student.update_all_stats
    student.update_last_assignment_for
  end

  def destination_organization
    @destination_organization
  end

  def transfer_guide_progress!
    transfer_item.update!(guide: guide_h,
                          student: new_student.dup,
                          organization: destination_organization.name,
                          course: new_course)
  end

  def guide_progress
    Mumuki::Classroom::GuideProgress.find_by(guide_progress_query)
  end

  def classroom_sibling_for(assignment)
    Mumuki::Classroom::Assignment.classroom_sibling_for(assignment, source_organization.name)
  end

  def new_student
    @new_student ||= student_for destination_organization.name
  end

  def old_student
    @old_student ||= student_for source_organization
  end

  def student_for(organization)
    Mumuki::Classroom::Student.last_updated_student_by organization: organization, uid: user.uid
  end

  def new_course
    new_student.course
  end

  def old_course
    old_student.course
  end

  def guide_progress_query
    {
      organization: source_organization,
      course: old_course,
      'guide.slug': guide.slug,
      'student.uid': user.uid
    }
  end

  def user
    indicator.user
  end

  def guide
    indicator.content
  end

  def guide_parent
    guide.usage_in_organization
  end

  def guide_h
    @guide_h ||= guide.as_json(
      only: [:slug, :name],
      include: {
        language: {
          only: [:name, :devicon]
        }
      }
    ).merge(
      parent: {
        type: guide_parent.class.to_s,
        name: guide.name,
        position: guide_parent.number,
        chapter: guide.chapter.as_json(only: [:id], methods: [:name])
      }
    )
  end
end
