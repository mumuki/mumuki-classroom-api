namespace :events do
  task :listen do
    Mumukit::Nuntius::EventConsumer.start 'classroom'
  end
end
