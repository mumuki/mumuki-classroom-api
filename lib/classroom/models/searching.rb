module Searching
  class SimpleFilter
    def self.query_for(param)
      {'$text': {'$search': param}}
    end

    def self.pipeline
      []
    end
  end

  def self.filter_for(criteria, collection)
    searching_module = "#{self}::#{collection.name}".constantize
    if criteria
      "#{searching_module}::#{criteria.camelize}".constantize
    else
      searching_module.default_filter
    end
  end
end

require_relative './searching/student'
require_relative './searching/guide_progress'
