def do_migrate!
  Classroom::Database.connect_each! do |organization|
    puts "Migrating organization #{organization}"
    Classroom::Collection::Courses.all.each do |course|
      for_course = course.slug.to_mumukit_slug.course

      all_guides = Classroom::Collection::Guides.for(for_course).all
      total_guides = all_guides.count

      all_guides.each_with_index do |guide, index|
        puts "  Migrating Guide #{index} of #{total_guides}"
        Classroom::Collection::GuideStudentsProgress.for(for_course).update_many({'guide.slug': guide.slug}, {'$set': {'guide': guide.as_json}})
        Classroom::Collection::ExerciseStudentProgress.for(for_course).update_many({'guide.slug': guide.slug}, {'$set': {'guide': guide.as_json}})
      end
    end
  end
end
