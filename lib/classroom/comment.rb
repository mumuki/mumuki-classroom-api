module Classroom::Comment
  extend Classroom::WithMongo

  class << self
    def collection_name
      'comments'
    end

    def where(criteria)
      find(criteria).projection(_id: 0)
    end

    def insert!(comment_json)
      insert_one(comment_json)
    end
  end
end
