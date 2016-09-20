module Classroom::Collection::Organizations

  extend Mumukit::Service::Collection

  def self.set_locale!(locale)
    mongo_collection.update_one({name: Classroom::Database.organization}, {:'$set' => { locale: locale }}, {upsert: true})
  end

  def self.locale
    find_by(name: Classroom::Database.organization).try(&:locale) || 'es'
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
