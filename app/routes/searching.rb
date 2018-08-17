helpers do
  def with_detached_and_search(params, collection)
    params
      .merge('detached': {'$exists': with_detached})
      .merge_unless(query.empty?, query_criteria_class_for(collection).query_for(query))
  end

  def query_criteria_class_for(collection)
    Searching.filter_for(query_criteria, collection)
  end
end
