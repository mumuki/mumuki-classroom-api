namespace :messages do
  task :listen do
    Mumuki::Classroom::Nuntius.logger.info 'Listening to student messages'

    Mumuki::Classroom::Nuntius.consumer.negligent_start! 'student-messages' do |body|
      begin
        Mumuki::Classroom::Nuntius.logger.info "Processing message #{body}"

        Message.import_from_json!(body).try do |assignment|
          Notification.import_from_json! 'Message', assignment
        end

      rescue => e
        Mumuki::Classroom::Nuntius.logger.warn "Message failed #{e}. body was: #{body}"
      end
    end
  end
end
