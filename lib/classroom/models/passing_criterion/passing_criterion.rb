module Exam::PassingCriterion
  def self.parse(criterion)
    raise unless "Exam::PassingCriterion::#{criterion[:type].camelize}".constantize.valid_passing_grade? criterion[:value]
  end
end

require_relative 'none'
require_relative 'passed_exercises'
require_relative 'percentage'
