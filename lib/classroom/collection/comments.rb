module Classroom::Collection::Comments

  extend Mumukit::Service::Collection

  private

  def self.mongo_collection_name
    :comments
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::Comment.new(it)
  end

  def self.wrap_array(it)
    Classroom::Collection::CommentArray.new(it)
  end

end

module Mumukit::Service::Collection
  def where(args)
    raw = mongo_collection.find(args).projection(_id: 0).map { |it| wrap it }
    wrap_array raw
  end
end
