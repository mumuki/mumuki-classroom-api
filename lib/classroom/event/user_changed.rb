class Classroom::Event::UserChanged
  class << self
    def execute!(user)
      update_user_permissions user
      update_user_model user
    end

    private

    def update_user_permissions(user)
      Mumukit::Auth::Store.new('permissions').tap do |db|
        set_diff_permissions db, user
        db.set! user['uid'], user['permissions']
        db.close
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
      permissions = db.get user['uid']
      @diff = Mumukit::Auth::PermissionsDiff.diff permissions, user['permissions']
    end

    def student_added(user, course_slug)
      json_body = user.except('uid', 'permissions').deep_symbolize_keys
      social_id = user['uid']
      Classroom::Collection::Courses.ensure_exist! course_slug
      Classroom::Collection::CourseStudents.ensure_new! social_id, course_slug
      Classroom::Collection::Students.for(course).ensure_new! social_id, json_body[:email]

      json = {student: json_body.merge(social_id: social_id), course: {slug: course_slug}}
      Classroom::Collection::CourseStudents.insert! json.wrap_json
      Classroom::Collection::Students.for(course).insert!(json[:student].wrap_json)
    end

  end
end
