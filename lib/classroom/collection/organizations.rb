module Classroom::Collection::Organizations

  extend Mumukit::Service::Collection

  def self.current
    find_by(criteria) || wrap(fetch)
  end

  def self.fetch
    Classroom::Atheneum.organization_json['organization'].tap do |data|
      update_one(criteria, data, upsert: true)
    end
  end

  def self.criteria
    { name: Classroom::Database.organization }
  end

  def self.locale
    current.locale
  end

  private

  def self.mongo_collection_name
    :organizations
  end

  def self.mongo_database
    Classroom::Database
  end

  def self.wrap(it)
    Classroom::JsonWrapper.new(it)
  end

end
