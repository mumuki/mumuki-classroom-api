class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def with_detached_and_search(params_hash, collection)
      params_hash
        .merge('detached': {'$exists': with_detached})
        .merge_if(params[:students] == 'follow', followers_criteria(collection))
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

    def followers_criteria(collection)
      uids = Mumuki::Classroom::Follower.find_by(with_organization_and_course email: current_user_uid)&.uids.to_a
      {collection.uid_field.to_sym => {'$in': uids}}
    end
  end
end
