helpers do
  def paginated_params
    {
      page: page,
      sort_by: sort_by,
      order_by: order_by,
      per_page: per_page,
      with_detached: with_detached,
      query: query
    }
  end
end
