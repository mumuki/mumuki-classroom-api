namespace :submissions do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to submissions'

    Mumukit::Nuntius::Consumer.negligent_start! 'submissions' do |body|
      begin
        Mumukit::Nuntius::Logger.info "Processing submission #{body['uid']}"
        Submission.process! body
      rescue => e
        Mumukit::Nuntius::Logger.warn "Submission failed #{e}. body was: #{body.except('test_results')}"
        FailedSubmission.create! body
      end
    end
  end
end
