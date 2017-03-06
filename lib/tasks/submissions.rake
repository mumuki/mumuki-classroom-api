namespace :submissions do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to submissions'

    Mumukit::Nuntius::Consumer.negligent_start! 'submissions' do |body|
      organization = body.delete('tenant')
      body[:organization] = organization
      Classroom::Database.connect!
      begin
        Mumukit::Nuntius::Logger.info "Processing submission #{body['id']}"
        Classroom::Submissions.process! body
      rescue => e
        Mumukit::Nuntius::Logger.warn "Submission failed #{e}. body was: #{body}"
        FailedSubmission.create! body
      end
    end
  end
end
