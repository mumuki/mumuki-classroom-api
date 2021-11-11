class Mumuki::Classroom::ExamAuthorizationRequest < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :pg_id, type: Integer
  field :status, type: String
  field :guide_slug, type: String
  field :organization, type: String
  field :exam_registration_id, type: Integer
  field :student, type: Hash

  create_index(pg_id: 1)
  create_index(organization: 1, 'student.course': 1, guide_slug: 1, 'student.uid': 1)
  create_index(exam_registration_id: 1)
  create_index(organization: 1, 'student.course': 1, 'student.uid': 1)
end
