class Assignment

  include Mongoid::Document
  include Mongoid::Timestamps

  field :guide, type: Hash
  field :student, type: Hash
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  field :exercise, type: Hash

  embeds_many :submissions

  store_in collection: 'exercise_student_progress'
  create_index({'organization': 1, 'course': 1, 'exercise.id': 1, 'student.uid': 1})

  def comment!(comment, sid)
    submissions.find_by!(sid: sid).comment! comment
    update_attributes! submissions: submissions
    notify_comment! comment, sid
  end

  def notify_comment!(comment, sid)
    Mumukit::Nuntius::Publisher.publish_comments json_to_notify(comment, sid)
  end

  def json_to_notify(comment, sid)
    {
      comment: comment,
      submission_id: sid,
      exercise_id: exercise[:id],
      tenant: organization
    }.as_json
  end

end


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
