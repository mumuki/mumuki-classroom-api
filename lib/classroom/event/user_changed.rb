class Classroom::Event::UserChanged
  class << self
    def execute!(user)
      user_h = user.with_indifferent_access
      update_user_permissions user_h
      update_user_model user_h
    end

    private

    def update_user_permissions(user)
      Mumukit::Auth::Store.with do |db|
        set_diff_permissions db, user
        db.set! user[:uid], user[:permissions]
      end
    end

    def update_user_model(user)
      @diff.each do |scope, diff|
        diff.each do |type, grants|
          grants.each do |grant|
            message = "#{type}_#{scope}"
            self.send message, user, grant if self.respond_to? message
          end
        end
      end
    end

    def set_diff_permissions(db, user)
      permissions = db.get user[:uid]
      @diff = Mumukit::Auth::PermissionsDiff.diff permissions, user[:permissions]
    end

    def student_added(user, course_slug)
      course = course_slug.to_mumukit_slug.course
      if Classroom::Collection::Students.for(course).exists? user[:uid]
        Classroom::Collection::Students.for(course).attach! user[:uid]
      else
        Classroom::Collection::CourseStudents.create user.except(:permissions), course_slug
      end
    end

    def student_removed(user, course_slug)
      course = course_slug.to_mumukit_slug.course
      Classroom::Collection::Students.for(course).detach! user[:uid]
    end

  end
end
