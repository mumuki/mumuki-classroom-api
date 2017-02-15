class Classroom::Collection::OrganizationCollection

  include Mumukit::Service::Collection

  def self.for(organization)
    self.new(organization)
  end

  def initialize(organization)
    @organization = organization
    create_index pk
  end

  def organization
    @organization
  end

  def insert!(args)
    super query(args.as_json).wrap_json
  end

  def find_by(args)
    super query(args)
  end

  def all
    where query
  end

  def count(args = {})
    mongo_collection.find(query args).count
  end

  def where(args)
    super query(args)
  end

  private

  def create_index(hash_index)
    mongo_database.client[mongo_collection_name].indexes.create_one hash_index
  end

  def pk
    {organization: 1}
  end

  def query(args = {})
    {organization: organization}.merge args
  end

  def mongo_collection_name
    underscore_class_name.to_sym
  end

  def underscore_class_name
    self.class.name.demodulize.underscore
  end

  def mongo_database
    Classroom::Database
  end

  def wrap(it)
    Classroom::JsonWrapper.new(it)
  end

  def wrap_array(it)
    Classroom::JsonArrayWrapper.new(it, underscore_class_name)
  end

end
