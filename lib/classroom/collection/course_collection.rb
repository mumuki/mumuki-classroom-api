class Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def self.for(course)
    self.new(course)
  end

  def initialize(course)
    @course = course.underscore
  end

  def course
    @course
  end

  private

  def mongo_collection_name
    "#{course}_#{underscore_class_name}".to_sym
  end

  def underscore_class_name
    self.class.name.demodulize.underscore
  end

  def mongo_database
    Classroom::Database
  end

  def wrap(it)
    Classroom::JsonWrapper.new(it)
  end

  def wrap_array(it)
    Classroom::JsonArrayWrapper.new(it, underscore_class_name)
  end

end
