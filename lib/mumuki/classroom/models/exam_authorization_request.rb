class Mumuki::Classroom::ExamAuthorizationRequest < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :pg_id, type: Integer
  field :status, type: Integer
  field :guide_slug, type: String
  field :exam_registration, type: Hash
  field :student, type: Hash
end
