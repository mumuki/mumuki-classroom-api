class Classroom::Database
  
  class << self

    include Mumukit::Service::Database

    attr_reader :organization

    def client
      @client
    end

    def organization=(organization)
      @organization = organization
      @client = new_database_client(organization)
    end

    def within_each(&block)
      client.database_names.each do |organization|
        self.organization = organization.to_sym
        block.call
      end
    end

  end

end
