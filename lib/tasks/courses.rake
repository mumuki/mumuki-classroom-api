namespace :courses do
  task :notify, [:migration_name] do |_t, args|
    Classroom::Database.connect!
    Organization.pluck(:name).each do |organization|
      puts "migrating #{organization}"
      Classroom::Collection::Courses.all.each_with_index do |course, index|
        puts "#{index}"
        Mumukit::Nuntius::EventPublisher.publish('CourseChanged', {course: course.as_json(except: [:name])})
      end
    end
  end
end
