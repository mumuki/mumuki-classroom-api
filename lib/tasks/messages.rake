namespace :messages do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to student messages'

    Mumukit::Nuntius::Consumer.negligent_start! 'student-messages' do |body|
      begin
        Mumukit::Nuntius::Logger.info "Processing message #{body}"
        Message.import_from_json! body
      rescue => e
        Mumukit::Nuntius::Logger.warn "Message failed #{e}. body was: #{body}"
      end
    end
  end
end
