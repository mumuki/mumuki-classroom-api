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
    submissions.find_by!(id: submission_id).add_comment! comment
    update_attributes! submissions: submissions
    notify_comment! comment, submission_id
  end

  def notify_comment!(comment, submission_id)
    Mumukit::Nuntius::Publisher.publish_comments json_to_notify(comment, submission_id)
  end

  def json_to_notify(comment, submission_id)
    {
      comment: comment,
      submission_id: submission_id,
      exercise_id: exercise.id,
      tenant: organization
    }.as_json
  end


end


class Exercise

  include Mongoid::Document

  field :id, type: Numeric
  field :name, type: String
  field :number, type: Numeric

end


class Submission

  include Mongoid::Document

  field :_id, type: String
  field :content, type: String
  field :created_at, type: Time
  field :expectation_results, type: Array
  field :feedback, type: String
  field :result, type: String
  field :status, type: String
  field :submissions_count, type: Numeric
  field :test_results, type: Array

  embeds_many :comments

  def add_comment!(comment)
    comments << Comment.new(comment)
  end

  def as_json(options = {})
    super(options).merge(id: _id).with_indifferent_access
  end

end


class Comment
  include Mongoid::Document

  field :date, type: Time, default: -> { Time.new }
  field :type, type: String
  field :email, type: String
  field :content, type: String

end
