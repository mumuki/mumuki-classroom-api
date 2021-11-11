class Mumuki::Classroom::ExamAuthorization < Mumuki::Classroom::Document
  field :pg_id, type: Integer
  field :session_id, type: String
  field :guide_slug, type: String
  field :organization, type: String
  field :student, type: Hash
  field :started, type: Mongoid::Boolean
  field :started_at, type: Time

  create_index(pg_id: 1)
  create_index(organization: 1, 'student.course': 1, guide_slug: 1, 'student.uid': 1)
end
