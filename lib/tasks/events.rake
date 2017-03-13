namespace :events do
  task :listen do
    Mumukit::Nuntius::EventConsumer.start!
  end
end
