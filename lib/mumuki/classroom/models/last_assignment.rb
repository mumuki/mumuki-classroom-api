class Mumuki::Classroom::LastAssignment

  include Mongoid::Document

  embeds_one :guide
  embeds_one :exercise
  embeds_one :submission, class_name: 'Mumuki::Classroom::Submission'

end
