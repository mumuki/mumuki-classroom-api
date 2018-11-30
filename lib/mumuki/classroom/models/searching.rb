module Searching
  VALID_PARAMS = [:query_param, :query_operand]

  class BaseFilter
    include ActiveModel::Model

    attr_accessor *VALID_PARAMS

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

  def self.filter_for(collection, query_params)
    filter_class = filter_class_for(query_params[:query_criteria], collection) || default_filter
    filter_class.new(valid_params(query_params))
  end

  def self.valid_params(params)
    params.select { |it| VALID_PARAMS.include? it }
  end

  def self.filter_class_for(criteria, collection)
    if criteria.present?
      "#{self}::#{collection.name.demodulize}::#{criteria.camelize}".safe_constantize
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
