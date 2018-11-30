module Mumuki::Classroom::Exam::PassingCriterion
  def self.parse(criterion)
    unless parse_criterion_type(criterion[:type]).valid_passing_grade? criterion[:value]
      raise "Invalid criterion value #{criterion[:value]} for #{criterion[:type]}"
    end
  end

  def self.parse_criterion_type(type)
    "Mumuki::Classroom::Exam::PassingCriterion::#{type.camelize}".constantize
  rescue
    raise "Invalid criterion type #{type}"
  end
end

require_relative 'none'
require_relative 'passed_exercises'
require_relative 'percentage'
