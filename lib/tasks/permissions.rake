namespace :permissions do

  task :resend, [:slug]  do |_t, args|
    slug = args[:slug].to_mumukit_slug
    organization = slug.organization
    course = slug.course
    Classroom::Database.with organization do
      students = Classroom::Collection::Students.for(course)
                                                .where('detached': {'$exists': false})
                                                .raw
      students_count = students.size
      puts "Total students to process: #{students_count}"

      students.each_with_index do |student, index|
        puts "Processing: #{index + 1} of #{students_count}"

        permissions = Mumukit::Auth::Store.get student.uid
        puts "    Actual Permissions: #{permissions.as_json}"

        new_permission = slug.to_s
        permissions.add_permission! :student, new_permission
        puts "    Adding Permission to: #{new_permission}"

        user_as_json = student.as_json(only: [:first_name, :last_name, :email, :uid])
        user_to_notify = user_as_json.merge(permissions: permissions.as_json)
        puts "    Publishing to: #{user_to_notify}"

        Mumukit::Nuntius::EventPublisher.publish 'UserChanged', {user: user_to_notify}
      end
    end
    puts "DONE :smile:"
  end
end
