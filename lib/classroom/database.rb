class Classroom::Database
  extend Mumukit::Service::Database

  class << self
    def client=(client)
      Thread.current.thread_variable_set :mongo_client, client
    end

    def client
      Thread.current.thread_variable_get :mongo_client
    end

    def organization
      client.database.name
    end

    def database_names
      client.database_names
    end

    def clean!(target = organization)
      connect_transient!(target) { client.collections.each(&:drop) }
    end

    def ensure!(target = organization)
      connect_transient!(target) { client[:classroom].insert_one classroom_db: true }
    end

    def connect!(organization)
      if client
        self.client = client.use(organization)
      else
        self.client = new_database_client(organization)
      end
    end

    def connect_each!(&block)
      database_names.each do |organization|
        connect_transient!(organization) { block.call organization }
      end
    end

    def connect_transient!(new_organization, &block)
      if new_organization == organization
        block.call
      else
        swap_and_call!(block, new_organization)
      end
    end

    private

    def swap_and_call!(block, new_organization)
      old_organization = organization
      connect! new_organization
      block.call
    ensure
      connect! old_organization
    end
  end
end
