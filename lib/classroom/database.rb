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
    block.call
  ensure
    disconnect!
  end

  class << self
    delegate :client, :organization, :disconnect!, to: :current_database

    def current_database
      Thread.current.thread_variable_get :current_database
    end

    def current_database=(database)
      Thread.current.thread_variable_set :current_database, database
    end

    def ensure!(organization)
      with(organization) { client[:classroom].insert_one classroom_db: true }
    end

    def connect!(organization)
      self.current_database = self.new(organization).tap(&:connect!)
    end

    # This method is here in order to easily do migrations
    def within_each(&block)
      with :test do
        client.database_names.each { |organization| with organization, &block }
      end
    end

    def with(organization, &block)
      old = self.current_database
      self.current_database = self.new(organization)
      current_database.with do
        block.call current_database
      end
    ensure
      self.current_database = old
    end
  end
end
