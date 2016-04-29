class Classroom::Database

  extend Mumukit::Service::Database

  def self.client
    @client
  end

  def self.tenant=(tenant)
    @client = new_database_client(tenant)
  end

end
