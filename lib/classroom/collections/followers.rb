class Classroom::Collection::Followers < Classroom::Collection::CourseCollection

  def add_follower(data)
    update_follower(data, '$addToSet')
  end

  def remove_follower(data)
    update_follower(data, '$pull')
  end

  private

  def update_follower(data, action)
    json = data.with_indifferent_access
    update_one(
      query(:email => json['email']),
      {action => {uids: json['uid']}},
      {:upsert => true})
  end

  def wrap(it)
    Classroom::Follower.new(it)
  end

end
