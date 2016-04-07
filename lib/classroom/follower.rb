class Classroom::Follower
  extend Classroom::WithMongo

  def self.add_follower(data)
    followers_collection.update_follower(data["course"], data["email"], data["social_id"], "$addToSet")
  end

  def self.remove_follower(data)
    followers_collection.update_follower(data["course"], data["email"], data["social_id"], "$pull")
  end

  def self.where(criteria)
    followers_collection.find(criteria).projection(_id: 0, email: 0)
  end

end
