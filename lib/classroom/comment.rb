module Classroom::Comment
  extend Classroom::WithMongo

  class << self
    def where(criteria)
      comments_collection.find(criteria).projection(_id: 0)
    end

    def insert!(course_json)
      comments_collection.insert_one(course_json)
    end

  end
end
