module Classroom::Follower
  extend Classroom::WithMongo

  class << self
    def collection_name
      'followers'
    end

    def add_follower(data)
      update_follower(data['course'], data['email'], data['social_id'], '$addToSet')
    end

    def remove_follower(data)
      update_follower(data['course'], data['email'], data['social_id'], '$pull')
    end

    def where(criteria)
      find(criteria).projection(_id: 0, email: 0)
    end

    private

    def update_follower(course, email, follower, action)
      update_one(
        { 'email' => email, 'course' => course },
        { action => { 'social_ids' => follower }},
        { :upsert => true })
    end
  end
end
