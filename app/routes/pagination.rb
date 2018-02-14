helpers do
  def paginated_params
    {
      page: page,
      sort_by: sort_by,
      order_by: order_by,
      per_page: per_page,
      with_detached: with_detached
    }
  end

  def with_detached_and_search(params)
    params
      .merge('detached': {'$exists': with_detached})
      .merge_unless(query.empty?, '$text': {'$search': query})
  end
end
