Mumukit::Nuntius::EventConsumer.handle do

  event :UserChanged do |payload|
    Classroom::Event::UserChanged.execute! payload[:user]
  end

  event :CourseChanged do |payload|
    Course.import_from_json! payload[:course]
  end

  event "OrganizationUpdated" do |payload|
    organization = payload[:organization]
    Organization.find_by!(name: organization[:name]).update! organization
  end

  event "OrganizationCreated" do |payload|
    Organization.create! payload[:organization]
  end

end
