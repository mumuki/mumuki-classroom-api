class Classroom::Database
  extend Mumukit::Service::Database

  attr_accessor :client, :organization

  def initialize(organization)
    @organization = organization.to_sym
  end

  def connect!
    self.client = self.class.new_database_client(organization)
  end

  def disconnect!
    client.try :close
  end

  def with(&block)
    connect!
    block.call(self)
  ensure
    disconnect!
  end

  class << self
    def client
      @current_database.try :client
    end

    def organization
      @current_database.try :organization
    end

    def connect!(organization)
      @current_database = self.new(organization)
      @current_database.connect!
    end

    def disconnect!
      @current_database.disconnect!
    end

    def with(organization, &block)
      instance_variable_swap :@current_database do
        @current_database = self.new(organization)
        @current_database.with(&block)
      end
    end
  end
end
