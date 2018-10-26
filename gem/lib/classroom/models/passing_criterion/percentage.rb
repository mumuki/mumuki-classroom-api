module Exam::PassingCriterion::Percentage
  def self.valid_passing_grade?(value)
    value.between? 0, 100
  end
end
