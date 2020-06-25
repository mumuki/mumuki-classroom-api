Mumukit::Nuntius::EventConsumer.handle do

  # Emitted by:
  #    * new logins in laboratory
  #    * user creation and modification in laboratory
  #    * user creation and modification in classroom
  event 'UserChanged' do |payload|
    Mumuki::Classroom::Event::UserChanged.execute! payload.deep_symbolize_keys[:user].except(:created_at, :updated_at)
  end
end
