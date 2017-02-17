class Classroom::Database

  extend Mumukit::Service::Database

  class << self
    def new_database_client(_)
      Mongo::Client.new(
        ["#{config[:host]}:#{config[:port]}"],
        database: default_database_name,
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
        self.client = new_database_client(default_database_name)
      end
    end

    def default_database_name
      config[:database]
    end

    def clean!
      client.collections.each(&:drop)
    end

    def connect!
      if client
        self.client = client.use(default_database_name)
      else
        self.client = new_database_client(default_database_name)
      end
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
