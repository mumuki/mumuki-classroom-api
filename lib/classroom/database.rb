class Classroom::Database

  class << self

    include Mumukit::Service::Database

    attr_reader :organization

    def client
      @client
    end

    def organization=(organization)
      @organization = organization.to_sym
      @client = new_database_client(@organization)
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
      self.organization = organization
      block.call
    ensure
      @client.try(:close)
    end
  end

end
