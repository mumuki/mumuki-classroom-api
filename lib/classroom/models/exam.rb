class Exam
  extend WithMongoIndex

  include Mongoid::Document
  include Mongoid::Timestamps
  include WithoutMongoId

  field :id, type: BSON::ObjectId, default: Mumukit::Service::IdGenerator.next
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
    Mumukit::Nuntius::EventPublisher.publish 'UpsertExam', json_to_notify
  end

  private

  def json_to_notify
    as_json(except: [:social_ids, :course, :created_at, :updated_at])
  end

end
