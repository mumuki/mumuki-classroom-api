namespace :submissions do
  task :listen do
    Mumuki::Classroom::Nuntius.logger.info 'Listening to submissions'

    Mumuki::Classroom::Nuntius.consumer.negligent_start! 'submissions' do |body|
      begin
        Mumuki::Classroom::Nuntius.logger.info "Processing submission #{body['uid']}"
        Submission.process! body
      rescue => e
        Mumuki::Classroom::Nuntius.logger.warn "Submission failed #{e}. body was: #{body.except('test_results')}"
        FailedSubmission.create! body
      end
    end
  end
end
