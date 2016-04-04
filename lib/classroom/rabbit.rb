class Classroom::Rabbit

  def self.config
    @config ||= YAML.load(ERB.new(File.read(File.expand_path '../../../config/rabbit.yml', __FILE__)).result).
        with_indifferent_access[ENV['RACK_ENV'] || 'development']
  end

  def self.publish(queue_name, data)
    conn = connection
    channel = conn.start.create_channel
    channel.tap { |ch| ch.queue(queue_name, durable: true) }
      .default_exchange
      .publish(data.to_json, :routing_key => queue_name, persistent: true)
    conn.close
  end

  def self.connection
    Bunny.new(host: config[:host],
              port: config[:port],
              user: config[:user],
              password: config[:password])
  end

  def self.method_missing(name, *args, &block)
    if name.to_s.starts_with? 'publish_'
      queue_name = name.to_s.split('publish_').last
      publish queue_name, args
    else
      super
    end
  end
end
