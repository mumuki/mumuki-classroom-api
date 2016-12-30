module Classroom::Collection::FailedSubmissions

  extend Mumukit::Service::Collection

  def self.find_by_uid(uid)
    where({ :'submitter.uid' => uid })
  end

  private

  def self.mongo_collection_name
    :failed_submissions
  end

  def self.mongo_database
    Classroom::Database
  end

end
