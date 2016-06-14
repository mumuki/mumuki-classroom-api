class Classroom::Database

  extend Mumukit::Service::Database

  class << self
    attr_reader :organization
  end

  def self.client
    @client
  end

  def self.tenant=(tenant)
    @organization = tenant
    @client = new_database_client(tenant)
  end

  def self.within_each(&block)
    client.database_names.each do |organization|
      self.tenant = organization.to_sym
      block.call
    end
  end

end
