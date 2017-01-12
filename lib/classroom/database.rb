class Classroom::Database
  extend Mumukit::Service::Database

  class << self
    def new_database_client(database)
      Mongo::Client.new(
        ["#{config[:host]}:#{config[:port]}"],
        database: database,
        user: config[:user],
        password: config[:password],
        min_pool_size: 1,
        max_pool_size: config[:pool])
    end

    def client=(client)
      Thread.current.thread_variable_set :mongo_client, client
    end

    def client
      Thread.current.thread_variable_get(:mongo_client).if_nil? do
        self.client = new_database_client(:classroom)
      end
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

class NilClass
  def if_nil?(&block)
    block.call
  end
end

class Object
  def if_nil?(&_block)
    self
  end
end
