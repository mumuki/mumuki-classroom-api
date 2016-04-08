module Classroom::WithMongo
  def method_missing(name, *args, &block)
    Classroom::Database.client[collection_name].send(name, *args, &block)
  end

  def find_one(*args)
    find(*args).first
  end

  def insert!(json)
    insert_one(json)
  end
end
