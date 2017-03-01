class Assignment

  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_one :guide
  embeds_one :student
  embeds_one :exercise
  embeds_many :submissions
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug

  store_in collection: 'exercise_student_progress'
  create_index({'organization': 1, 'course': 1, 'exercise.id': 1, 'student.uid': 1})

  def comment!(comment, submission_id)
    submissions.find_by!(id: submission_id).push(comments: comment)
  end

end


class Submission

  include Mongoid::Document

  field :id, type: String
  field :content, type: String
  field :comments, type: Array
  field :created_at, type: Time
  field :expectation_results, type: Array
  field :feedback, type: String
  field :result, type: String
  field :status, type: String
  field :submissions_count, type: Numeric
  field :test_results, type: Array

end


class Exercise

  include Mongoid::Document

  field :id, type: Numeric
  field :name, type: String
  field :number, type: Numeric

end
