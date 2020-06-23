namespace :classroom do
  namespace :submissions do
    task :listen do
      Mumukit::Nuntius::Logger.info 'Listening to submissions'

      Mumukit::Nuntius::Consumer.negligent_start! 'submissions' do |body|
        begin
          Mumukit::Nuntius::Logger.info "Processing submission #{body['uid']}"
          Mumuki::Classroom::Submission.process! body
        rescue => e
          Mumukit::Nuntius::Logger.warn "Mumuki::Classroom::Submission failed #{e}. body was: #{body.except('test_results')}"
          Mumuki::Classroom::FailedSubmission.create! body
        end
      end
    end
  end
end
