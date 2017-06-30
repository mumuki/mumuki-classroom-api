class Suggestion

  include Mongoid::Document
  include Mongoid::Timestamps

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :date, type: String
  field :guide_slug, type: String

  embeds_one :exercise
  embeds_many :submissions

  create_index({'guide_slug': 1, 'exercise.eid': 1})

  def times_used
    self.submissions.count
  end

  def add_submission!(submission)
    self.submissions << submission
    self.update_attributes! submissions: submissions
  end

  def self.create_from(message, assignment)
    self.create message.merge(guide_slug: assignment.guide['slug'], exercise: assignment.exercise)
  end
end
