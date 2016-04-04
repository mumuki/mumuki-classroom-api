module Classroom::Comment
  extend Classroom::WithMongo

  class << self
    def where(criteria)
      comments_collection.find(criteria).projection(_id: 0)
    end

    def insert!(comment_json)
      comments_collection.insert_one(comment_json)
    end

  end
end
