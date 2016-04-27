class Classroom::Course < Mumukit::Service::JsonWrapper

  def initialize(it)
    super(it.except(:id))
  end

end
