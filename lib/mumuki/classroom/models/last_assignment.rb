class Mumuki::Classroom::LastAssignment < Mumuki::Classroom::Document

  field :guide, type: Hash
  embeds_one :exercise
  embeds_one :submission, class_name: 'Mumuki::Classroom::Submission'

end
