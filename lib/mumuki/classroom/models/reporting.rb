module Reporting

  def self.build_pipeline(collection, query, paginated_params, query_params, projection)
    ordering = "#{Criteria.name}::#{paginated_params[:order_by].to_s.camelize}".constantize
    sorting = "#{Sorting.name}::#{collection.name.demodulize}::By#{paginated_params[:sort_by].to_s.camelize}".constantize
    searching = Searching.filter_for(collection, query_params)
    pipeline query, sorting, ordering, searching, projection
  end

  def self.aggregate(collection, query, paginated_params, query_params, projection)
    pipeline = build_pipeline(collection, query, paginated_params, query_params, projection)
    collection.collection.aggregate pipeline
  end

  def self.pipeline(query, sorting, ordering, searching, projection)
    main_pipeline = []
    main_pipeline << {'$match': query}
    main_pipeline.concat searching.pipeline
    main_pipeline.concat sorting.pipeline
    main_pipeline << {'$sort': sorting.order_by(ordering)}
    main_pipeline << {'$project': projection}
  end

end
