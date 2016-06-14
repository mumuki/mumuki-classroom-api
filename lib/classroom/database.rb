class Classroom::Database

  extend Mumukit::Service::Database

  class << self
    attr_reader :organization
  end

  def self.client
    @client
  end

  def self.organization=(organization)
    @organization = organization
    @client = new_database_client(organization)
  end

  def self.within_each(&block)
    client.database_names.each do |organization|
      self.organization = organization.to_sym
      block.call
    end
  end

end
