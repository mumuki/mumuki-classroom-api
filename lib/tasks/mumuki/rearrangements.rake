namespace :rearrangements do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to rearrangements'

    Mumukit::Nuntius::Consumer.negligent_start! 'rearrangements' do |body|
      Mumukit::Nuntius::Logger.info "Processing rearrangement #{body[:profile][:uid]}"
      Mumuki::Classroom::Event::UserChanged.rearrange! body
    end
  end
end
