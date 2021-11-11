class Mumuki::Classroom::Certificate < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :pg_id, type: Integer
  field :code, type: String
  field :certificate_program, type: Hash
  field :student, type: Hash
  field :started_at, type: Time
  field :ended_at, type: Time
end
