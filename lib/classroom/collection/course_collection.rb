class Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def self.for(course)
    self.new(course)
  end

  def initialize(course)
    @course = course.underscore
  end

  private

  def mongo_collection_name
    "#{@course}_#{self.class.name.demodulize.underscore}".to_sym
  end

  def mongo_database
    Classroom::Database
  end

  def wrap(it)
    Classroom::JsonWrapper.new(it)
  end

end
