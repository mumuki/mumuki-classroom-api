module Classroom::WithMongo
  def method_missing(name, *args, &block)
    if name.to_s.end_with? '_collection'
      collection_name = name.to_s.split('_collection').first
      Classroom::Database.client[collection_name]
    else
      super
    end
  end
end
