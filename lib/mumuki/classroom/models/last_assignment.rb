class Mumuki::Classroom::LastAssignment < Mumuki::Classroom::Document

  embeds_one :guide
  embeds_one :exercise
  embeds_one :submission, class_name: 'Mumuki::Classroom::Submission'

end
