class Classroom::Collection::Followers < Classroom::Collection::CourseCollection

  def add_follower(data)
    update_follower(data, '$addToSet')
  end

  def remove_follower(data)
    update_follower(data, '$pull')
  end

  private

  def update_follower(data, action)
    update_one(
      { 'email' => data['email'], 'course' => data['course'] },
      { action => { 'social_ids' => data['social_id'] }},
      { :upsert => true })
  end

  def wrap(it)
    Classroom::Follower.new(it)
  end

end
