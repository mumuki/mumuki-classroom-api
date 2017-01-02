class Classroom::Event::UserChanged
  class << self

    attr_accessor :changes

    def execute!(user)
      update_user_permissions user[:user]
      update_user_model user[:user].except(:permissions)
    end

    private

    def update_user_permissions(user)
      Mumukit::Auth::Store.with do |db|
        set_diff_permissions db, user
        db.set! user[:uid], user[:permissions]
      end
    end

    def update_user_model(user)
      Classroom::Database.within_each do |database|
        update_student user
        changes[database.organization]&.each do |change|
          message = change.description
          self.send message, user, change.granted_slug if self.respond_to? message, true
        end
      end
    end

    def set_diff_permissions(db, user)
      permissions = db.get user[:uid]
      self.changes = Mumukit::Auth::Permissions::Diff.diff(permissions, user[:permissions]).changes_by_organization
    end

    def update_student(user)
      Classroom::Collection::CourseStudents.find_by_uid(user[:uid]).try do |course_student|
        course_h = course_student.course.as_json.with_indifferent_access
        old_profile = Mumukit::Auth::Profile.extract course_student.student
        new_profile = Mumukit::Auth::Profile.extract user
        update_student! course_h, new_profile.attributes if old_profile != new_profile
      end
    end


    def update_student!(course_h, student_h)
      course = course_h[:uid].to_mumukit_slug.course
      sub_student = student_h.transform_keys { |field| "student.#{field}".to_sym }
      Classroom::Collection::Students.for(course).update! student_h
      Classroom::Collection::CourseStudents.update_student! sub_student
      Classroom::Collection::GuideStudentsProgress.for(course).update_student! sub_student
      Classroom::Collection::ExerciseStudentProgress.for(course).update_student! sub_student
    end

    def student_added(user, granted_slug)
      if Classroom::Collection::Students.for(granted_slug.course).exists? user[:uid]
        Classroom::Collection::Students.for(granted_slug.course).attach! user[:uid]
      else
        Classroom::Collection::CourseStudents.create! user, granted_slug.to_s
      end
    end

    def student_removed(user, granted_slug)
      Classroom::Collection::Students.for(granted_slug.course).detach! user[:uid]
    end

    def teacher_added(user, granted_slug)
      Classroom::Collection::Teachers.for(granted_slug.course).upsert! user
    end

  end
end
