module Classroom::Comment
  extend Classroom::WithMongo

  class << self
    def collection_name
      'comments'
    end

    def where(criteria)
      find(criteria).projection(_id: 0)
    end
  end
end
