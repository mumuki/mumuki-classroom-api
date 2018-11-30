class Mumuki::Classroom::FailedSubmission

  extend WithFailedSubmissionReprocess

  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :created_at, type: Time

  create_index 'organization': 1, 'submitter.uid': 1
  create_index({'guide.slug': 1, 'exercise.eid': 1}, {name: 'ExBibIdIndex'})

  scope :for, -> (organization) { where 'organization': organization }
  scope :find_by_uid, -> (uid) { where 'submitter.uid': uid }


end
