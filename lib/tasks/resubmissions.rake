namespace :resubmissions do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to resubmissions'

    Mumukit::Nuntius::Consumer.negligent_start! 'resubmissions' do |body|
      begin
        destination = body.delete('tenant')
        social_id = body['social_id']

        Mumukit::Nuntius::Logger.info "Processing resubmission #{social_id}"
        Classroom::FailedSubmission.reprocess! social_id, destination
      ensure
        Classroom::Database.disconnect!
      end
    end
  end
end

