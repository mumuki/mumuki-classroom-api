Mumukit::Nuntius::EventConsumer.handle do

  event 'UserChanged' do |payload|
    Classroom::Event::UserChanged.execute! payload[:user]
  end

  event 'CourseChanged' do |payload|
    Course.import_from_json! payload[:course]
  end

  event 'OrganizationChanged' do |payload|
    organization = payload[:organization]
    Organization.find_by!(name: organization[:name]).update! organization
  end

  event 'OrganizationCreated' do |payload|
    Organization.create! payload[:organization]
  end

  event 'ExerciseChanged' do |payload|
    guide = payload[:guide]
    exercises = payload[:exercises]
    puts "Migrating: #{guide[:slug]}"
    exercises.each do |e|
      puts "Migrating: #{[e[:id], e[:bibliotheca_id]]}"
      Student.where('last_assignment.guide.slug': guide[:slug], 'last_assignment.exercise.eid': e[:id]).update_all 'last_assignment.exercise.eid': e[:bibliotheca_id]
      Assignment.where('guide.slug': guide[:slug], 'exercise.eid': e[:id]).update_all 'exercise.eid': e[:bibliotheca_id]
      GuideProgress.where('guide.slug': guide[:slug], 'last_assignment.exercise.eid': e[:id]).update_all 'last_assignment.exercise.eid': e[:bibliotheca_id]
      FailedSubmission.where('guide.slug': guide[:slug], 'exercise.eid': e[:id]).update_all 'exercise.eid': e[:bibliotheca_id]
    end
    puts "Done: #{guide[:slug]}\n\n\n"
  end

end
