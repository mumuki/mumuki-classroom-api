module Searching
  class BaseFilter
    include ActiveModel::Model
    attr_accessor :query_param, :query_operand

    def query
      {}
    end

    def pipeline
      []
    end
  end

  class StudentFilter < BaseFilter
    def query
      {'$text': {'$search': query_param}}
    end
  end

  class NumericFilter < BaseFilter
    def query_param=(query_param)
      @query_param = query_param.to_i
    end
  end

  def self.default_filter
    StudentFilter
  end

  def self.filter_for(criteria, collection, query, query_operand)
    filter_class = filter_class_for(criteria, collection) || default_filter
    filter_class.new(query_param: query, query_operand: query_operand)
  end

  def self.filter_class_for(criteria, collection)
    if criteria.present?
      "#{self}::#{collection.name}::#{criteria.camelize}".safe_constantize
    end
  end

  module QueryOperands
    def current_query_operand
      send current_query_operand_method, query_param
    end

    def current_query_operand_method
      query_operand || default_query_operand
    end
  end
end

require_relative './searching/guide_progress'
