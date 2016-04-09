module Classroom::Follower
  extend Classroom::WithMongo

  class << self
    def collection_name
      'followers'
    end

    def add_follower(data)
      update_follower(data, '$addToSet')
    end

    def remove_follower(data)
      update_follower(data, '$pull')
    end

    def where(criteria)
      find(criteria).projection(_id: 0, email: 0)
    end

    private

    def update_follower(data, action)
      update_one(
        { 'email' => data['email'], 'course' => data['course'] },
        { action => { 'social_ids' => data['social_id'] }},
        { :upsert => true })
    end
  end
end
