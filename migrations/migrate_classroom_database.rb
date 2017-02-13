DATABASE = :classroom

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
  Classroom::Collection::Courses.all.each do |course_object|
    course_slug = course_object.slug || course_object.uid
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
  to_insert = doc['created_at'] ? doc : doc.merge(created_at: doc['_id'].generation_time)
  to_insert = to_insert.merge(merge_options)
  Classroom::Database.client[to_collection].insert_one to_insert
rescue Mongo::Error::MaxBSONSize => _
  puts "        [WARNING] :: {_id: ObjectId('#{doc['_id']}')} is to large and some submissions will be removed"
  to_insert['submissions'] = to_insert['submissions'].first_and_last(10)
  Classroom::Database.client[to_collection].insert_one to_insert
end

class Array
  def first_and_last(n)
    self.first(n).concat self.last(n)
  end
end
