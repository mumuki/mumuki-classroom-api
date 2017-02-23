module WithMongoIndex

  def create_index(*args)
    index *args
    create_indexes
  end

end
