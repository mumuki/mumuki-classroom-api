class Mumuki::Classroom::Event::UserChanged
  class << self

    attr_accessor :changes

    def execute!(user_h)
      user = User.slice_resource_h user_h.compact
      set_diff_permissions user
      update_user_model user.except(:permissions)
      User.import_from_resource_h! user # FIXME we must refactor events
    end

    private

    def update_user_model(user)
      Organization.pluck(:name).each do |organization|
        update_student organization, user
        changes[organization]&.each do |change|
          message = change.description
          self.send message, organization, user, change.granted_slug if self.respond_to? message, true
        end
      end
    end

    def set_diff_permissions(user)
      permissions = User.find_or_create_by!(uid: user[:uid]).permissions
      self.changes = Mumukit::Auth::Permissions::Diff.diff(permissions, user[:permissions]).changes_by_organization
    end

    def update_student(organization, user)
      Mumuki::Classroom::Student.last_updated_student_by(organization: organization, uid: user[:uid]).try do |student|
        old_profile = Mumukit::Auth::Profile.extract student
        new_profile = Mumukit::Auth::Profile.extract user
        update_student! organization, student.course, new_profile.attributes if old_profile != new_profile
      end
    end


    def update_student!(organization, course_slug, student_h)
      sub_student = student_h.transform_keys { |field| "student.#{field}".to_sym }
      Mumuki::Classroom::Student.find_by!(organization: organization, course: course_slug, uid: student_h[:uid]).update_attributes! student_h
      Mumuki::Classroom::GuideProgress.where(organization: organization, course: course_slug, 'student.uid': student_h[:uid]).update_all sub_student
      Mumuki::Classroom::Assignment.where(organization: organization, course: course_slug, 'student.uid': student_h[:uid]).update_all sub_student
    end

    def student_added(organization, user, granted_slug)
      students = Mumuki::Classroom::Student.where(organization: organization, course: granted_slug.to_s, uid: user[:uid])
      if students.exists?
        students.first.attach!
      else
        Mumuki::Classroom::Student.create! user.merge(organization: organization, course: granted_slug.to_s)
      end
    end

    def student_removed(organization, user, granted_slug)
      student = Mumuki::Classroom::Student.find_by!(organization: organization, course: granted_slug.to_s, uid: user[:uid])
      student.detach!
    end

    def teacher_added(organization, user, granted_slug)
      teacher = Mumuki::Classroom::Teacher.find_or_create_by!(organization: organization, course: granted_slug.to_s, uid: user[:uid])
      teacher.update_attributes! user
    end

  end
end
