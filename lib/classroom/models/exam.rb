class Exam

  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, type: String, default: -> { Mumukit::Service::IdGenerator.next }
  field :uids, type: Array
  field :name, type: String
  field :slug, type: String
  field :course, type: String
  field :end_time, type: String
  field :language, type: String
  field :duration, type: Numeric
  field :start_time, type: String
  field :organization, type: String

  create_index({organization: 1, course: 1, id: 1}, {unique: true})

  def add_student!(uid)
    add_to_set uids: uid
  end

  def notify!
    Mumukit::Nuntius.notify_event! 'UpsertExam', json_to_notify
  end

  def as_json(options = {})
    {id: _id}.as_json(options).merge(super options)
  end

  private

  def json_to_notify
    as_json(except: [:social_ids, :course, :created_at, :updated_at])
  end

end
