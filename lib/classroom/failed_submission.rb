require 'mumukit/nuntius'

module Classroom::FailedSubmission

  def self.reprocess!(social_id, destination)
    reprocess_from_organization social_id, destination, destination
    reprocess_from_organization social_id, :central, destination
  end

  def self.reprocess_from_organization(social_id, source, destination)
    Classroom::Database.with source do
      Classroom::Collection::FailedSubmissions.find_by_social_id(social_id).raw.each do |failed_submission|
        delete_failed_submission failed_submission, source
        try_reprocess failed_submission, source, destination
      end
    end
  end

  def self.try_reprocess(failed_submission, source, destination)
    begin
      reprocess_failed_submission destination, failed_submission
    rescue => e
      Mumukit::Nuntius::Logger.warn "Resubmission failed #{e}. it was: #{failed_submission.raw}"
      insert_failed_submission failed_submission, source
    end
  end

  def self.insert_failed_submission(failed_submission, source)
    Classroom::Database.with source do
      Classroom::Collection::FailedSubmissions.insert! failed_submission
    end
  end

  def self.reprocess_failed_submission(destination, it)
    Classroom::Database.with destination do
      Classroom::Submission.process! it.raw
    end
  end

  def self.delete_failed_submission(it, source)
    Classroom::Database.with source do
      Classroom::Collection::FailedSubmissions.delete! it.id
    end
  end

end
