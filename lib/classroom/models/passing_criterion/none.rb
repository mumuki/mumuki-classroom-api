module Exam::PassingCriterion::None
  def self.valid_passing_grade?(value)
    !value
  end
end
