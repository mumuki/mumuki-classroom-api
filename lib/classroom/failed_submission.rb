module Classroom::FailedSubmission
  extend Classroom::WithMongo

  class << self
    def collection_name
      'failed_submissions'
    end

    def insert!(data)
      insert_one data
    end
  end

end
