class Mumuki::Classroom::Event::UserChanged
  class << self

    attr_accessor :changes

    def execute!(user_h)
      set_diff_permissions user_h
      update_user_model user_h
    end

    private

    def update_user_model(user)
      Organization.pluck(:name).each do |organization|
        changes[organization]&.each do |change|
          message = change.description
          self.send message, organization, user, change.granted_slug if self.respond_to? message, true
        end
      end
    end

    def set_diff_permissions(user)
      self.changes = Mumukit::Auth::Permissions::Diff.diff(user[:old_permissions], user[:new_permissions]).changes_by_organization
    end

    def student_added(organization, user, granted_slug)
      uid = user[:uid]
      students = Mumuki::Classroom::Student.where(organization: organization, course: granted_slug.to_s, uid: uid)
      if students.exists?
        students.first.attach!
      else
        student = Mumuki::Classroom::Student.attributes_from_user uid
        Mumuki::Classroom::Student.create! student.merge(organization: organization, course: granted_slug.to_s)
      end
    end

    def student_removed(organization, user, granted_slug)
      student = Mumuki::Classroom::Student.find_by!(organization: organization, course: granted_slug.to_s, uid: user[:uid])
      student.detach!
    end

    def teacher_added(organization, user, granted_slug)
      uid = user[:uid]
      teacher = Mumuki::Classroom::Teacher.find_or_create_by!(organization: organization, course: granted_slug.to_s, uid: uid)
      teacher.update_attributes!(Mumuki::Classroom::Teacher.attributes_from_user(uid))
    end

    def teacher_removed(organization, user, granted_slug)
      teacher = Mumuki::Classroom::Teacher.find_by!(organization: organization, course: granted_slug.to_s, uid: user[:uid])
      teacher.destroy!
    end

  end
end
