class Classroom::FailedSubmission < Mumukit::Service::JsonWrapper

  def initialize(it)
    super(it.except(:id))
  end

end
