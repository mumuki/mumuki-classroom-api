class Classroom::Event::UserChanged
  class << self

    attr_accessor :changes

    def execute!(user)
      update_user_permissions user[:user]
      update_user_model user[:user].except(:permissions)
    end

    private

    def update_user_permissions(user)
      set_diff_permissions user
      Classroom::Collection::Users.find_by_uid!(user[:uid]).update!(permissions: user[:permissions])
    end

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
      permissions = Classroom::Collection::Users.find_by_uid!(user[:uid]).permissions
      self.changes = Mumukit::Auth::Permissions::Diff.diff(permissions, user[:permissions]).changes_by_organization
    end

    def update_student(organization, user)
      Student.last_updated_student_by(organization: organization, uid: user[:uid]).try do |student|
        old_profile = Mumukit::Auth::Profile.extract student
        new_profile = Mumukit::Auth::Profile.extract user
        update_student! organization, student.course, new_profile.attributes if old_profile != new_profile
      end
    end


    def update_student!(organization, course_slug, student_h)
      sub_student = student_h.transform_keys { |field| "student.#{field}".to_sym }
      Student.find_by!(uid: student_h[:uid], organization: organization, course: course_slug).update_attributes! student_h
      GuideProgress.where(organization: organization, course: course_slug).update_all sub_student
      Assignment.where(organization: organization, course: course_slug).update_all sub_student
    end

    def student_added(organization, user, granted_slug)
      if Student.where(uid: user[:uid], organization: organization, course: granted_slug.to_s).exists?
        Student.find_by!(uid: user[:uid], organization: organization, course: granted_slug.to_s).attach!
      else
        Student.create! user.merge(organization: organization, course: granted_slug.to_s)
      end
    end

    def student_removed(organization, user, granted_slug)
      Student.find_by!(uid: user[:uid], organization: organization, course: granted_slug.to_s).detach!
    end

    def teacher_added(organization, user, granted_slug)
      Classroom::Collection::Teachers.for(organization, granted_slug.course).upsert! user
    end

  end
end
