module Classroom::FailedSubmission

  def self.reprocess!(social_id, destination, logger=nil)
    reprocess_current_organization social_id, destination, logger
    reprocess_central social_id, destination, logger
  end

  def self.reprocess_current_organization(social_id, destination, logger)
    Classroom::Database.organization = destination
    Classroom::Collection::FailedSubmissions.find_by_social_id(social_id).raw.each do |it|
      Classroom::Collection::FailedSubmissions.delete! it.id
      begin
        Classroom::Submission.process! it.raw
      rescue => e
        logger.warn "Resubmission failed #{e}. it was: #{it.raw}" if logger.present?
        Classroom::Collection::FailedSubmissions.insert! it
      end
    end
    Classroom::Database.client.try(:close)
  end

  def self.reprocess_central(social_id, destination, logger)
    Classroom::Database.with :central do
      Classroom::Collection::FailedSubmissions.find_by_social_id(social_id).raw.each do |it|
        Classroom::Database.with :central do
          Classroom::Collection::FailedSubmissions.delete! it.id
        end
        begin
          Classroom::Database.with destination do
            Classroom::Submission.process! it.raw
          end
        rescue => e
          Classroom::Database.with :central do
            logger.warn "Resubmission failed #{e}. it was: #{it.raw}" if logger.present?
            Classroom::Collection::FailedSubmissions.insert! it
          end
        end
      end
    end
  end

end
