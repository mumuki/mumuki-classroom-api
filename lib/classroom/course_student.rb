class Classroom::CourseStudent < Mumukit::Service::JsonWrapper

  def initialize(it)
    super(it.except(:id))
  end

end
