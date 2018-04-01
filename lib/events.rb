Mumukit::Nuntius::EventConsumer.handle do

  # Emitted by:
  #    * new logins in laboratory
  #    * user creation and modification in laboratory
  #    * user creation and modification in classroom
  event 'UserChanged' do |payload|
    Classroom::Event::UserChanged.execute! payload[:user].except(:created_at, :updated_at)
  end

  # Emitted by course creation and modification in laboratory
  event 'CourseChanged' do |payload|
    Course.import_from_json! payload[:course].except(:created_at, :updated_at)
  end

  # Emitted by organization creation and modification in laboratory
  event 'OrganizationChanged' do |payload|
    Organization.import_from_json! payload[:organization].except(:created_at, :updated_at)
  end
end
