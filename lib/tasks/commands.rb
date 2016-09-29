namespace :commands do
  task :listen do
    Mumukit::Nuntius::CommandConsumer.start 'classroom'
  end
end
