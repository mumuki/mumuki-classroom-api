module Classroom::Collection::FailedSubmissions

  extend Mumukit::Service::Collection

  private

  def self.mongo_collection_name
    :failed_submissions
  end

  def self.mongo_database
    Classroom::Database
  end

end
