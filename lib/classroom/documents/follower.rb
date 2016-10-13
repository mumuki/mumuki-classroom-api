class Classroom::Follower < Classroom::JsonWrapper

  def initialize(it)
    super(it.except(:email))
  end

end
