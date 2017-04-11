module Classroom::Collection::Organizations

  extend Mumukit::Service::Collection

  def self.upsert!(organization)
    mongo_collection.update_one(
      {:name => organization['name']},
      {:$set => organization},
      {:upsert => true}
    )
  end

  def self.login_method_present?(organization, key, value)
    if organization['lock_json'].present?
      (organization['lock_json']['connections'] & [key, value]).present?
    else
      organization['login_methods'].include? key
      (organization['login_methods'] & [key, value]).present?
    end
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
