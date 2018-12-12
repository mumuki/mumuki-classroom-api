class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def with_detached_and_search(params, collection)
      params
        .merge('detached': {'$exists': with_detached})
        .merge_unless(query_params[:query_param].empty?, query_criteria_class_for(collection).query)
    end

    def query_criteria_class_for(collection)
      Searching.filter_for(collection, query_params)
    end

    def query_params
      {
        query_param: query,
        query_criteria: query_criteria,
        query_operand: query_operand
      }
    end
  end
end
