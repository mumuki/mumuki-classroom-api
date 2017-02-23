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
      Classroom::Collection::CourseStudents.for(organization).find_by_uid(user[:uid]).try do |course_student|
        course_h = course_student.course.as_json.with_indifferent_access
        old_profile = Mumukit::Auth::Profile.extract course_student.student
        new_profile = Mumukit::Auth::Profile.extract user
        update_student! organization, course_h, new_profile.attributes if old_profile != new_profile
      end
    end


    def update_student!(organization, course_h, student_h)
      course_slug = course_h[:uid] || course_h[:slug]
      course = course_slug.to_mumukit_slug.course
      sub_student = student_h.transform_keys { |field| "student.#{field}".to_sym }
      Classroom::Collection::Students.for(organization, course).update! student_h
      Classroom::Collection::CourseStudents.for(organization).update_student! sub_student
      Classroom::Collection::GuideStudentsProgress.for(organization, course).update_student! sub_student
      Classroom::Collection::ExerciseStudentProgress.for(organization, course).update_student! sub_student
    end

    def student_added(organization, user, granted_slug)
      if Classroom::Collection::Students.for(organization, granted_slug.course).exists? user[:uid]
        Classroom::Collection::Students.for(organization, granted_slug.course).attach! user[:uid]
      else
        Classroom::Collection::CourseStudents.for(organization).create! user, granted_slug.to_s
      end
    end

    def student_removed(organization, user, granted_slug)
      Classroom::Collection::Students.for(organization, granted_slug.course).detach! user[:uid]
    end

    def teacher_added(organization, user, granted_slug)
      Classroom::Collection::Teachers.for(organization, granted_slug.course).upsert! user
    end

  end
end
