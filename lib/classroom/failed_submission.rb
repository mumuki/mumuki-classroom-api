module Classroom::FailedSubmission

  def self.reprocess!(social_id, destination, logger=nil)
    [destination, :central].each do |source|
      Classroom::Database.organization = source
      failed_submissions = Classroom::Collection::FailedSubmissions.find_by_social_id(social_id)

      failed_submissions.raw.each do |it|
        Classroom::Database.organization = source
        Classroom::Collection::FailedSubmissions.delete! it.id
        begin
          Classroom::Database.organization = destination
          Classroom::Submission.process! it.raw
        rescue => e
          logger.warn "Resubmission failed #{e}. it was: #{it.raw}" unless logger
          Classroom::Database.organization = source
          Classroom::Collection::FailedSubmissions.insert! it
        end
      end
    end
  end

end
