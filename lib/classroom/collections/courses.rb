module Classroom::Collection::Courses

  extend Mumukit::Service::Collection

  def self.allowed(grants_pattern)
    where(uid: {'$regex' => grants_pattern})
  end

  def self.ensure_new!(uid)
    raise Classroom::CourseExistsError, "#{uid} does already exist" if any?(uid: uid)
  end

  def self.ensure_exist!(uid)
    raise Classroom::CourseNotExistsError, "#{uid} does not exist" unless any?(uid: uid)
  end

  def self.upsert!(course)
    mongo_collection.update_one(
      {'uid': course[:uid]},
      {'$set': course.as_json(except: :uid)},
      {'upsert': true}
    )
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
    Classroom::JsonArrayWrapper.new(it, :courses)
  end

end


class Classroom::CourseExistsError < StandardError
end

class Classroom::CourseNotExistsError < StandardError
end
