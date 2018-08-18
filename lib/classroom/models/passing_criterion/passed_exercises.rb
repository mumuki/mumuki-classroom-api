module Exam::PassingCriterion::PassedExercises
  def self.valid_passing_grade?(value)
    value >= 0
  end
end
