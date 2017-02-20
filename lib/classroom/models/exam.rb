class Exam < Document

  field :id, type: String, default: generate_id
  field :uids, type: Array
  field :name, type: String
  field :slug, type: String
  field :course, type: String
  field :end_time, type: String
  field :language, type: String
  field :duration, type: Numeric
  field :start_time, type: String
  field :organization, type: String

  index organization: 1, course: 1, id: 1

  def add_student!(uid)
    add_to_set uids: uid
  end

  def notify!
    Mumukit::Nuntius::EventPublisher.publish 'UpsertExam', json_to_notify
  end

  private

  def json_to_notify
    as_json(except: [:social_ids, :course, :created_at, :updated_at])
  end

end
