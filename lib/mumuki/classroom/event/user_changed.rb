class Mumuki::Classroom::Event::UserChanged
  class << self

    def execute!(user_h)
      user_h = user_h.compact

      old_permissions = User.locate(user_h[:uid]).permissions
      new_permissions_h = user_h[:permissions]

      User.import_from_resource_h! user_h # FIXME we must refactor events

      diff_h = Mumukit::Auth::Permissions::Diff.diff(old_permissions, new_permissions_h).as_json

      rearrange!  profile: user_h.except(:permissions),
                  permissions: { new: new_permissions_h, diff: diff_h }.compact
    end

    def rearrange!(rearrangement)
      profile = Mumukit::Auth::Profile.extract rearrangement[:profile]
      diff = Mumukit::Auth::Permissions::Diff.parse rearrangement[:permissions][:diff]
      update_user_roles! profile, diff.changes_by_organization
      rearrangement
    end

    private

    def update_user_roles!(profile, changes)
      Organization.pluck(:name).each do |organization|
        update_student! organization, profile
        changes[organization]&.each do |change|

          message = change.description
          self.send message, organization, profile.attributes, change.granted_slug if self.respond_to? message, true
        end
      end
    end

    def update_student!(organization, new_profile)
      student_h = new_profile.attributes
      Mumuki::Classroom::Student.last_updated_student_by(organization: organization, uid: student_h[:uid]).try do |student|
        old_profile = Mumukit::Auth::Profile.extract student
        update_student_embeddings! organization, student.course, student_h if old_profile != new_profile
      end
    end

    def update_student_embeddings!(organization, course_slug, student_h)
      sub_student = student_h.transform_keys { |field| "student.#{field}".to_sym }
      Mumuki::Classroom::Student.find_by!(organization: organization, course: course_slug, uid: student_h[:uid]).update_attributes! student_h
      Mumuki::Classroom::GuideProgress.where(organization: organization, course: course_slug, 'student.uid': student_h[:uid]).update_all sub_student
      Mumuki::Classroom::Assignment.where(organization: organization, course: course_slug, 'student.uid': student_h[:uid]).update_all sub_student
    end

    def student_added(organization, student_h, granted_slug)
      students = Mumuki::Classroom::Student.where(organization: organization, course: granted_slug.to_s, uid: student_h[:uid])
      if students.exists?
        students.first.attach!
      else
        Mumuki::Classroom::Student.create! student_h.merge(organization: organization, course: granted_slug.to_s)
      end
    end

    def student_removed(organization, student_h, granted_slug)
      student = Mumuki::Classroom::Student.find_by!(organization: organization, course: granted_slug.to_s, uid: student_h[:uid])
      student.detach!
    end

    def teacher_added(organization, teacher_h, granted_slug)
      teacher = Mumuki::Classroom::Teacher.find_or_create_by!(organization: organization, course: granted_slug.to_s, uid: teacher_h[:uid])
      teacher.update_attributes! teacher_h
    end

  end
end
