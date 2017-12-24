module Sorting

  def self.aggregate(collection, query, params)
    ordering = "#{Criteria.name}::#{params[:order_by].to_s.camelize}".constantize
    sorting = "#{name}::#{collection.name}::By#{params[:sort_by].to_s.camelize}".constantize
    [collection.where(query).count, collection.collection.aggregate(pipeline query, params, sorting, ordering)]
  end

  def self.pipeline(query, params, sorting, ordering)
    pipeline = []
    pipeline << {'$match': query}
    pipeline.concat sorting.pipeline
    pipeline << {'$project': projection}
    pipeline << {'$sort': sorting.order_by(ordering)}
    pipeline << {'$skip': params[:page] * params[:per_page]}
    pipeline << {'$limit': params[:per_page]}
  end

  def self.projection
    {
      '_id': 0,
      'assignments': 0,
      'notifications': 0,
      'guide._id': 0,
      'student._id': 0,
      'last_assignment._id': 0,
      'last_assignment.guide._id': 0,
      'last_assignment.exercise._id': 0,
      'last_assignment.submission._id': 0,
    }
  end

  class SortBy
    def self.pipeline
      []
    end
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
