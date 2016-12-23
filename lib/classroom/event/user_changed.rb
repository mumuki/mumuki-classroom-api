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
      json_body = user.except(:uid, :permissions).deep_symbolize_keys
      uid = user[:uid]
      Classroom::Collection::Courses.ensure_exist! course_slug
      Classroom::Collection::CourseStudents.ensure_new! uid, course_slug
      Classroom::Collection::Students.for(course).ensure_new! uid

      json = {student: json_body.merge(uid: uid), course: {slug: course_slug}}
      Classroom::Collection::CourseStudents.insert! json.wrap_json
      Classroom::Collection::Students.for(course).insert!(json[:student].wrap_json)
    end

  end
end
