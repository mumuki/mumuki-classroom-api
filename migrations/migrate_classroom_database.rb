class Classroom::Database
  extend Mumukit::Service::Database

  class << self
    def new_database_client(database)
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
      connect_transient!(target) { client[default_database_name].insert_one classroom_db: true }
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

DATABASE = Classroom::Database.default_database_name

def do_migrate!
  Classroom::Database.connect_each! do |organization|
    puts "Migrating #{organization}:"
    next if %w(classroom demo datos-haskell).include? organization.to_s
    migrate_collections_without_suffix organization
    migrate_collections_with_suffix organization
  end
  rename_permissions_to_users
rescue Exception => e
  puts "[Error - #{e.class}]#{e}"
end

def migrate_collections_without_suffix(organization)
  puts "   Migrating collections without suffix from #{organization}"
  copy_from_to(organization, 'organizations', DATABASE, 'organizations')
  %w(course_students courses failed_submissions).each do |collection|
    copy_from_to(organization, collection, DATABASE, collection, organization: organization)
  end
end

def migrate_collections_with_suffix(organization)
  puts "   Migrating collections with suffix from #{organization}"
  Classroom::Database.client[:courses].find.each do |course_object|
    course_slug = course_object['slug'] || course_object['uid']
    course = course_slug.to_mumukit_slug.course.underscore
    %w(exams exercise_student_progress followers guide_students_progress guides students teachers).each do |collection|
      copy_from_to organization, "#{collection}_#{course}", DATABASE, collection,
                   organization: organization, course: course_slug
    end
  end
end

def rename_permissions_to_users
  copy_from_to(DATABASE, 'permissions', DATABASE, 'users')
end

def copy_from_to(from_database, from_collection, to_database, to_collection, merge_options = {})
  puts "      Copying documents from #{from_database}.#{from_collection} to #{to_database}.#{to_collection}"
  Classroom::Database.connect_transient! from_database.to_sym do
    docs = Classroom::Database.client[from_collection].find
    Classroom::Database.connect_transient! to_database.to_sym do
      docs.each { |doc| insert_with_bson_size_limit doc, to_collection, merge_options }
    end
  end
end

def insert_with_bson_size_limit(doc, to_collection, merge_options)
  dateify! doc
  to_insert = doc['created_at'] ? doc : doc.merge(created_at: doc['_id'].generation_time)
  to_insert = to_insert.merge(merge_options)
  Classroom::Database.client[to_collection].insert_one to_insert
rescue Mongo::Error::MaxBSONSize => _
  puts "        [WARNING] :: {_id: ObjectId('#{doc['_id']}')} is to large and some submissions will be removed"
  to_insert['submissions'] = to_insert['submissions'].first_and_last(10)
  Classroom::Database.client[to_collection].insert_one to_insert
rescue Mongo::Error::OperationFailure => _
  puts "        [WARNING] :: {uid: '#{doc['uid']}')} is duplicated"
end

def dateify!(doc)
  do_dateify! doc
  if doc.dig('last_assignment', 'submission').present?
    do_dateify! doc['last_assignment']['submission']
  end
  if doc['submissions'].present?
    doc['submissions'].each { |d| do_dateify! d }
  end
end

def do_dateify!(doc)
  doc['created_at'] = Time.parse doc['created_at'] if doc['created_at'].is_a? String
  doc['updated_at'] = Time.parse doc['updated_at'] if doc['updated_at'].is_a? String
end

class Array
  def first_and_last(n)
    self.first(n).concat self.last(n)
  end
end

