module Classroom::WithMongo
  def method_missing(name, *args, &block)
    collection_name = name.to_s.split('_collection').first
    if collection_name
      Classroom::Database.client[collection_name]
    else
      super
    end
  end
end
