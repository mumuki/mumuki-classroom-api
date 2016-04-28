module Mumukit::Service::Collection

  def where(args, projection={})
    raw = mongo_collection.find(args).projection(projection.merge(_id: 0)).map { |it| wrap it }
    wrap_array raw
  end

  def order_by(args, options, projection={})
    mongo_collection.find(args).sort(options).projection(projection.merge(_id: 0)).first.try{ |it| wrap(it) }
  end

end
