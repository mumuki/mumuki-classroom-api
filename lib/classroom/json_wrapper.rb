class Classroom::JsonWrapper < Mumukit::Service::JsonWrapper

  def initialize(it)
    super(it.except(:id))
  end

end

class Classroom::JsonArrayWrapper < Mumukit::Service::JsonArrayWrapper

  def initialize(it, key)
    super(it)
    @key = key.to_sym
  end

  def key
    @key
  end

end
