class Mumuki::Classroom::Certificate < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :pg_id, type: Integer
  field :code, type: String
  field :certificate_program_id, type: Integer
  field :organization, type: String
  field :student, type: Hash
  field :started_at, type: Time
  field :ended_at, type: Time

  create_index(pg_id: 1)
  create_index(organization: 1, 'student.course': 1, 'student.uid': 1)
  create_index(certificate_program_id: 1)
end
