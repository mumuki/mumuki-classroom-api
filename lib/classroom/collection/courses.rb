module Classroom::Collection::Courses

  extend Mumukit::Service::Collection

  def self.all(grants_pattern)
    where(slug: {'$regex' => grants_pattern})
  end

  def self.ensure_new!(slug)
    raise Classroom::CourseExistsError, "#{slug} does already exist" if any?(slug: slug)
  end

  def self.ensure_exist!(slug)
    raise Classroom::CourseNotExistsError, "#{slug} does not exist" unless any?(slug: slug)
  end

  private

  def self.mongo_collection_name
    :courses
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::JsonWrapper.new(it)
  end

  def self.wrap_array(it)
    Classroom::Collection::CourseArray.new(it)
  end

end


class Classroom::CourseExistsError < StandardError
end

class Classroom::CourseNotExistsError < StandardError
end
