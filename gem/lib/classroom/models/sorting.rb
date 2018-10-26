module Sorting

  def self.aggregate(collection, query, paginated_params, query_params)
    reporting_pipeline = Reporting.build_pipeline(collection, query, paginated_params, query_params, projection)
    query = collection.collection.aggregate(pipeline paginated_params, reporting_pipeline).first
    query_results(query)
  end

  def self.query_results(query)
    total = query[:total].first
    [total.blank? ? 0 : total[:count], query[:results]]
  end

  def self.pipeline(params, pipeline)
    paging_pipeline = []
    paging_pipeline << {'$skip': params[:page] * params[:per_page]}
    paging_pipeline << {'$limit': params[:per_page]}
    pipeline << {'$facet': {
      results: paging_pipeline,
      total: [
        {
          '$count': 'count'
        }
      ]
    }}
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
  module Base
    def bson_type
      value.bson_type
    end

    def to_bson(*args)
      value.to_bson(*args)
    end

    def !
      negated
    end
  end

  module Asc
    extend Criteria::Base

    def self.value
      1
    end

    def self.negated
      Desc
    end
  end

  module Desc
    extend Criteria::Base

    def self.value
      -1
    end

    def self.negated
      Asc
    end
  end
end

require_relative './sorting/total_stats_sort_by'
require_relative './sorting/student'
require_relative './sorting/guide_progress'
