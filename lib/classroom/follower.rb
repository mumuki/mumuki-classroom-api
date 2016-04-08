class Classroom::Follower
  extend Classroom::WithMongo

  def self.collection_name
    'followers'
  end

  def self.add_follower(data)
    update_follower(data["course"], data["email"], data["social_id"], "$addToSet")
  end

  def self.remove_follower(data)
    update_follower(data["course"], data["email"], data["social_id"], "$pull")
  end

  def self.where(criteria)
    find(criteria).projection(_id: 0, email: 0)
  end

  private

  def self.update_follower(course, email, follower, action)
    update_one(
      { "email" => email, "course" => course },
      { action => { "social_ids" => follower }},
      { :upsert => true })
  end
end
