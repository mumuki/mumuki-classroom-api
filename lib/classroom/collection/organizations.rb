module Classroom::Collection::Organizations

  extend Mumukit::Service::Collection

  def self.upsert!(organization)
    mongo_collection.update_one(
      { :name => organization['name'] },
      { :$set => organization },
      { :upsert => true }
    )
  end

  private

  def self.mongo_collection_name
    :organizations
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::JsonWrapper.new(it)
  end

end
