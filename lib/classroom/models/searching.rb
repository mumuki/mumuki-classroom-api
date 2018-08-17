module Searching
  class BaseFilter
    def initialize(query_param)
      @query_param = query_param
    end

    def query
      {}
    end

    def pipeline
      []
    end
  end

  class StudentFilter < BaseFilter
    def query
      {'$text': {'$search': @query_param}}
    end
  end

  def self.default_filter
    StudentFilter
  end

  def self.filter_for(criteria, collection, query)
    filter_class = filter_class_for(criteria, collection) || default_filter
    filter_class.new(query)
  end

  def self.filter_class_for(criteria, collection)
    if criteria.present?
      "#{self}::#{collection.name}::#{criteria.camelize}".safe_constantize
    end
  end
end

require_relative './searching/guide_progress'
