class Mumuki::Classroom::Suggestion < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :date, type: String
  field :guide_slug, type: String
  field :times_used, type: Integer

  before_save :update_times_used

  embeds_one :exercise
  embeds_many :submissions, class_name: 'Mumuki::Classroom::Submission'

  create_index({'guide_slug': 1, 'exercise.eid': 1})

  def add_submission!(submission)
    update_attributes! submissions: submissions + [submission]
  end

  def content_html
    Mumukit::ContentType::Markdown.to_html content
  end

  def self.create_from(message, assignment)
    create message.merge(guide_slug: assignment.guide['slug'], exercise: assignment.exercise)
  end

  private

  def update_times_used
    self.times_used = submissions.size
  end
end
