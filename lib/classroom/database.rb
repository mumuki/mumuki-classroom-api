module Classroom::Database

  class << self

    include Mumukit::Service::Database

    attr_reader :organization

    def client
      @client
    end

    def connect!(organization)
      @organization = organization.to_sym
      @client = new_database_client(@organization)
    end

    def disconnect!
      client.try(:close)
    end

    def within_each(&block)
      client.database_names.each { |organization| self.with organization, &block }
    end

    def with(organization, &block)
      actual_client = @client
      actual_organization = @organization
      do_with organization, &block
      @organization = actual_organization
      @client = actual_client
    end

    private

    def do_with(organization, &block)
      connect! organization
      block.call
    ensure
      disconnect!
    end
  end

end
