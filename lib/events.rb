Mumukit::Nuntius::EventConsumer.handle do


  event 'UserChanged' do |payload|
    Classroom::Event::UserChanged.execute! payload[:user].except(:created_at, :updated_at)
  end

  event 'CourseChanged' do |payload|
    Course.import_from_json! payload[:course].except(:created_at, :updated_at)
  end

  event 'OrganizationChanged' do |payload|
    Organization.import_from_json! payload[:organization].except(:created_at, :updated_at)
  end
end
