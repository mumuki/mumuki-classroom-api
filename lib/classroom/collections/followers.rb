class Classroom::Collection::Followers < Classroom::Collection::CourseCollection

  def add_follower(data)
    update_follower(data, '$addToSet')
  end

  def remove_follower(data)
    update_follower(data, '$pull')
  end

  def delete_follower!(course_slug, social_id)
    update_many(
      { 'course' => course_slug },
      { '$pull' => { 'social_ids' => social_id }},
      { :upsert => true })
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
