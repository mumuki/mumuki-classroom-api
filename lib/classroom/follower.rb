class Classroom::Follower < Mumukit::Service::JsonWrapper

  def initialize(it)
    super(it.except(:id, :email))
  end

end
