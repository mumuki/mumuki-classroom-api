namespace :submission do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to submissions'

    Mumukit::Nuntius::Consumer.negligent_start! 'submissions' do |body|
      Classroom::Database.with body.delete('tenant') do
        begin
          Mumukit::Nuntius::Logger.info "Processing submission #{body['id']}"
          Classroom::Submission.process! body
        rescue => e
          Mumukit::Nuntius::Logger.warn "Submission failed #{e}. body was: #{body}"
          Classroom::Collection::FailedSubmissions.insert! body.wrap_json
        end
      end
    end
  end
end