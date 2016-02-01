module Classroom::Course
  extend Classroom::WithMongo

  class << self
    def where(criteria)
      courses_collection.find(criteria).projection(_id: 0)
    end

    def find_by(criteria)
      where(criteria).first
    end

    def count
      courses_collection.count
    end

    def insert!(course_json)
      courses_collection.insert_one(course_json)
    end

    def all(grants_pattern)
      where slug: {'$regex' => grants_pattern}
    end

    def ensure_new!(name)
      raise Classroom::CourseExistsError if courses_collection.count(name: name) > 0
    end
  end
end

class Classroom::CourseExistsError < StandardError
end