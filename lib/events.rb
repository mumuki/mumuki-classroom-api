Mumukit::Nuntius::EventConsumer.handle do

  event :UserChanged do |payload|
    Classroom::Event::UserChanged.execute! payload[:user]
  end

  event :CourseChanged do |payload|
    Course.import_from_json! payload[:course]
  end

  [:Created, :Changed].each do |it|
    event "Organization#{it}".to_sym do |payload|
      organization = payload[:organization]
      Organization.find_or_create_by!(name: organization[:name]).update_attributes! organization
    end
  end

end
