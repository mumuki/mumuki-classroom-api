module Reporting

  def self.build_pipeline(collection, query, params, projection)
    ordering = "#{Criteria.name}::#{params[:order_by].to_s.camelize}".constantize
    sorting = "#{Sorting.name}::#{collection.name}::By#{params[:sort_by].to_s.camelize}".constantize
    searching = Searching.filter_for(params[:query_criteria], collection, params[:query], params[:query_operand])
    pipeline query, sorting, ordering, searching, projection
  end

  def self.aggregate(collection, query, params, projection)
    pipeline = build_pipeline(collection, query, params, projection)
    collection.collection.aggregate pipeline
  end

  def self.pipeline(query, sorting, ordering, searching, projection)
    main_pipeline = []
    main_pipeline << {'$match': query}
    main_pipeline.concat searching.pipeline
    main_pipeline.concat sorting.pipeline
    main_pipeline << {'$project': projection}
    main_pipeline << {'$sort': sorting.order_by(ordering)}
  end

end
