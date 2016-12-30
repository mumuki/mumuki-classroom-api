class Classroom::Event::UserChanged
  class << self

    attr_accessor :diffs

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
      update_student user
      diffs.each do |scope, diff|
        diff.each do |type, grants|
          grants.each do |grant|
            message = "#{scope}_#{type}"
            Classroom::Database.with grant.to_mumukit_slug.organization do
              self.send message, user, grant if self.respond_to? message, true
            end
          end
        end
      end
    end

    def set_diff_permissions(db, user)
      permissions = db.get user[:uid]
      self.diffs = Mumukit::Auth::PermissionsDiff.diff permissions, user[:permissions]
    end

    def values
      [:uid, :social_id, :email, :name, :first_name, :last_name, :image_url]
    end

    def update_student(user)
      Classroom::Collection::CourseStudents.find_by_uid(user[:uid]).try do |course_student|
        course_h = course_student.course.as_json.with_indifferent_access
        student_h = course_student.student.as_json(only: values).with_indifferent_access
        user_h = user.as_json(only: values).with_indifferent_access
        update_student! course_h, user_h if has_changes?(student_h, user_h)
      end
    end

    def has_changes?(student_h, user_h)
      user_h != student_h
    end

    def update_student!(course_h, student_h)
      course = course_h[:uid].to_mumukit_slug.course
      sub_student = student_h.transform_keys { |field| "student.#{field}".to_sym }
      Classroom::Collection::Students.for(course).update! student_h
      Classroom::Collection::CourseStudents.update_student! sub_student
      Classroom::Collection::GuideStudentsProgress.for(course).update_student! sub_student
      Classroom::Collection::ExerciseStudentProgress.for(course).update_student! sub_student
    end

    def student_added(user, course_slug)
      course = course_slug.to_mumukit_slug.course
      if Classroom::Collection::Students.for(course).exists? user[:uid]
        Classroom::Collection::Students.for(course).attach! user[:uid]
      else
        Classroom::Collection::CourseStudents.create! user, course_slug
      end
    end

    def student_removed(user, course_slug)
      Classroom::Collection::Students.for(course_slug.to_mumukit_slug.course).detach! user[:uid]
    end

    def teacher_added(user, course_slug)
      Classroom::Collection::Teachers.for(course_slug.to_mumukit_slug.course).upsert! user
    end

  end
end
