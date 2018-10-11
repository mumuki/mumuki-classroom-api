namespace :events do
  task :listen do
    Mumuki::Classroom::Nuntius.event_consumer.start!
  end
end
