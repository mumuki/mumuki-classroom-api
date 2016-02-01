class Classroom::Database
  def self.client
    @client
  end

  def self.config
    @config ||= YAML.load(ERB.new(File.read('config/database.yml')).result).
        with_indifferent_access[ENV['RACK_ENV'] || 'development']
  end

  def self.tenant=(tenant)
    @client = Mongo::Client.new(
        ["#{config[:host]}:#{config[:port]}"],
        database: tenant,
        user: config[:user],
        password: config[:password])
  end

  def self.clean!
    client[:guide_progress].drop
    client[:courses].drop
    client[:course_students].drop
  end
end