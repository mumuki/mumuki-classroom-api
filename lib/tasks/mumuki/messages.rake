namespace :classroom do
  namespace :messages do
    task :listen do
      Mumukit::Nuntius::Logger.info 'Listening to student messages'

      Mumukit::Nuntius::Consumer.negligent_start! 'student-messages' do |body|
        begin
          Mumukit::Nuntius::Logger.info "Processing message #{body}"

          Mumuki::Classroom::Message.import_from_json!(body).try do |assignment|
            Mumuki::Classroom::Notification.import_from_json! 'Mumuki::Classroom::Message', assignment
          end

        rescue => e
          Mumukit::Nuntius::Logger.warn "Mumuki::Classroom::Message failed #{e}. body was: #{body}"
        end
      end
    end
  end
end
