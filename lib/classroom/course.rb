module Classroom::Course
  extend Classroom::WithMongo

  class << self
    def count
      courses_collection.count
    end

    def insert!(course_json)
      courses_collection.insert_one(course_json)
    end

    def all(grants_pattern)
      courses_collection.find(slug: {'$regex' => grants_pattern}).projection(_id: 0)
    end
  end
end
