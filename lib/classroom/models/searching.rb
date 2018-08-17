module Searching
  class StudentFilter
    def self.query_for(param)
      {'$text': {'$search': param}}
    end

    def self.pipeline
      []
    end
  end

  def self.default_filter
    StudentFilter
  end

  def self.filter_for(criteria, collection)
    filter_class_for(criteria, collection) || default_filter
  end

  def self.filter_class_for(criteria, collection)
    if criteria.present?
      "#{self}::#{collection.name}::#{criteria.camelize}".safe_constantize
    end
  end
end

require_relative './searching/guide_progress'
