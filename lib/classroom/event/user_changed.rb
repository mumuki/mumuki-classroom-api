class Classroom::Event::UserChanged
  class << self
    def execute!(user)
      update_user_permissions user
      update_user_model user
    end

    private

    def update_user_permissions(user)
      Mumukit::Auth::Store.new('permissions').tap do |db|
        db.set! user.uid, user['permissions']
        db.close
      end
    end

    def update_user_model(user)
      # TODO
    end
  end
end
