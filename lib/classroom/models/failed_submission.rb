class FailedSubmission

  extend WithFailedSubmissionReprocess
 
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :created_at, type: Time

  create_index 'organization': 1, 'submitter.uid': 1

  scope :for, -> (organization) { where 'organization': organization }
  scope :find_by_uid, -> (uid) { where 'submitter.uid': uid }


end
