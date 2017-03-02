class Submission

  include Mongoid::Document

  field :sid, type: String
  field :content, type: String
  field :created_at, type: String
  field :expectation_results, type: Array
  field :feedback, type: String
  field :result, type: String
  field :status, type: String
  field :submissions_count, type: Numeric
  field :test_results, type: Array
  field :comments, type: Array

  def comment!(comment)
    self.comments ||= []
    self.comments << comment
  end

end
