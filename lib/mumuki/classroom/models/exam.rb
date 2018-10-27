class Exam

  include Mongoid::Document
  include Mongoid::Timestamps

  field :eid, type: String, default: -> { SecureRandom.hex(8) }
  field :uids, type: Array
  field :name, type: String
  field :slug, type: String
  field :course, type: String
  field :end_time, type: String
  field :language, type: String
  field :duration, type: Integer
  field :max_problem_submissions, type: Integer
  field :max_choice_submissions, type: Integer
  field :passing_criterion, type: Hash
  field :start_time, type: String
  field :organization, type: String

  validates :max_problem_submissions, :max_choice_submissions, numericality: {greater_than_or_equal_to: 1}, allow_nil: true
  validate :passing_criterion_is_ok

  create_index({organization: 1, course: 1, eid: 1}, {unique: true})

  def add_student!(uid)
    add_to_set uids: uid
  end

  def remove_student!(uid)
    pull uids: uid
  end

  def notify!
    Mumukit::Nuntius.notify_event! 'UpsertExam', json_to_notify
  end

  private

  def json_to_notify
    as_json(except: [:social_ids, :course, :created_at, :updated_at, :id, :_id])
  end

  def passing_criterion_is_ok
    PassingCriterion.parse passing_criterion.with_indifferent_access
  end
end
