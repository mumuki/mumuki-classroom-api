module Classroom::Collection::Followers

  extend Mumukit::Service::Collection

  def self.add_follower(data)
    update_follower(data, '$addToSet')
  end

  def self.remove_follower(data)
    update_follower(data, '$pull')
  end

  private

  def self.update_follower(data, action)
    update_one(
      { 'email' => data['email'], 'course' => data['course'] },
      { action => { 'social_ids' => data['social_id'] }},
      { :upsert => true })
  end

  def self.mongo_collection_name
    :followers
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::Follower.new(it)
  end

  def self.wrap_array(it)
    Classroom::Collection::FollowerArray.new(it)
  end

end
