class Mumuki::Classroom::FailedSubmission < Mumuki::Classroom::Document

  extend WithFailedSubmissionReprocess

  include Mongoid::Attributes::Dynamic

  include Mongoid::Timestamps::Created

  create_index 'organization': 1, 'submitter.uid': 1
  create_index({'guide.slug': 1, 'exercise.eid': 1}, {name: 'ExBibIdIndex'})

  scope :for, -> (organization) { where 'organization': organization }
  scope :find_by_uid, -> (uid) { where 'submitter.uid': uid }


  def as_assignment_submission
    as_json(only: %i(sid status result content feedback created_at test_results submissions_count expectation_results origin_ip)).compact
  end
end
