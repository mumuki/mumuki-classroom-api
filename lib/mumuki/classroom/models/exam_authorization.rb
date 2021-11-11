class Mumuki::Classroom::ExamAuthorization < Mumuki::Classroom::Document
  field :pg_id, type: Integer
  field :guide_slug, type: String
  field :student, type: Hash
  field :started, type: Mongoid::Boolean
end
