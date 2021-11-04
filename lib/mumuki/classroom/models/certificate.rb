class Mumuki::Classroom::Certificate < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :code, type: String
  field :certificate_program_id, type: Integer
  field :user, type: Hash

  create_index({'user.uid': 1})
  create_index({'certificate_program_id': 1})
end
