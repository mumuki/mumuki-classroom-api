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
    Classroom::JsonWrapper.new(it)
  end

  def self.wrap_array(it)
    Classroom::Collection::CommentArray.new(it)
  end

end
