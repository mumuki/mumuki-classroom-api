class Suggestion

  include Mongoid::Document
  include Mongoid::Timestamps

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :date, type: String
  field :guide_slug, type: String
  field :times_used, type: Integer

  before_save :update_times_used

  embeds_one :exercise
  embeds_many :submissions

  create_index({'guide_slug': 1, 'exercise.eid': 1})

  def add_submission!(submission)
    self.submissions << submission
    self.update_attributes! submissions: submissions
  end

  def self.create_from(message, assignment)
    self.create message.merge(guide_slug: assignment.guide['slug'], exercise: assignment.exercise)
  end

  private

  def update_times_used
    self.times_used = self.submissions.size
  end
end
