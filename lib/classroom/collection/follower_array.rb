class Classroom::Collection::FollowerArray < Mumukit::Service::JsonArrayWrapper

  def options
    {only: [:course, :social_ids]}
  end

  def key
    :followers
  end

end
