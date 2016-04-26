class Classroom::Comment < Mumukit::Service::JsonWrapper

  def initialize(it)
    super(it.except(:id))
  end

end
