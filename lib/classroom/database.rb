class Classroom::Database
  extend Mumukit::Service::Database

  attr_accessor :organization

  def initialize(organization)
    @organization = organization.to_sym
  end

  def client
    @client ||= self.class.new_database_client(organization)
  end

  def connect!
    client
  end

  def disconnect!
    client.try :close
  end

  def with(&block)
    connect!
    block.call @organization
  ensure
    disconnect!
  end

  class << self
    delegate :client, :organization, :disconnect!, to: :@current_database

    def ensure!(organization)
      with(organization) { client.collections }
    end

    def connect!(organization)
      @current_database = self.new(organization)
      @current_database.connect!
    end

    # This method is here in order to easily do migrations
    def within_each(&block)
      with :test do
        client.database_names.each { |organization| with organization, &block }
      end
    end

    def with(organization, &block)
      instance_variable_swap :@current_database do
        @current_database = self.new(organization)
        @current_database.with(&block)
      end
    end
  end
end
