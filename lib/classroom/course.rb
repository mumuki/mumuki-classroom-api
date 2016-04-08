module Classroom::Course
  extend Classroom::WithMongo

  class << self
    def collection_name
      'courses'
    end

    def where(criteria)
      find(criteria).projection(_id: 0)
    end

    def find_by(criteria)
      where(criteria).first
    end

    def insert!(course_json)
      insert_one(course_json)
    end

    def all(grants_pattern)
      where slug: {'$regex' => grants_pattern}
    end

    def ensure_new!(slug)
      raise Classroom::CourseExistsError, "#{slug} does already exist" if count(slug: slug) > 0
    end

    def ensure_exist!(slug)
      raise Classroom::CourseNotExistsError, "#{slug} does not exist" if count(slug: slug) == 0
    end
  end
end

class Classroom::CourseExistsError < StandardError
end

class Classroom::CourseNotExistsError < StandardError
end
