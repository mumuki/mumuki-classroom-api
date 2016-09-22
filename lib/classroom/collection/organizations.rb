module Classroom::Collection::Organizations

  extend Mumukit::Service::Collection

  def self.current
    orga = find_by(criteria)
    orga.tap { |orga| update_one(criteria, Classroom::Atheneum.organization_json['organization'], upsert: true) unless orga.present? }
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
