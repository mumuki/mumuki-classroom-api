module Sorting

  def self.aggregate(collection, query, params)
    ordering = "#{Criteria.name}::#{params[:order_by].to_s.camelize}".constantize
    sorting = "#{name}::#{collection.name}::By#{params[:sort_by].to_s.camelize}".constantize
    [collection.where(query).count, collection.collection.aggregate(pipeline ordering, params, query, sorting)]
  end

  def self.pipeline(ordering, params, query, sorting)
    pipeline = []
    pipeline << {'$match': query}
    pipeline.concat sorting.pipeline if sorting.respond_to? :pipeline
    pipeline << {'$project': {'_id': false}}
    pipeline << {'$sort': sorting.order_by(ordering)}
    pipeline << {'$skip': params[:page] * params[:per_page]}
    pipeline << {'$limit': params[:per_page]}
  end

end

module Criteria
  module Asc
    def self.value
      1
    end

    def self.negated
      Desc
    end
  end

  module Desc
    def self.value
      -1
    end

    def self.negated
      Asc
    end
  end
end

require_relative './sorting/student'
require_relative './sorting/guide_progress'
