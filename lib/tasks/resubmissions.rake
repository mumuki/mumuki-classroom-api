namespace :resubmissions do
  task :listen do
    Mumuki::Classroom::Nuntius.logger.info 'Listening to resubmissions'

    Mumuki::Classroom::Nuntius.consumer.negligent_start! 'resubmissions' do |body|
      destination = body['tenant']
      uid = body['uid']

      Mumuki::Classroom::Nuntius.logger.info "Processing resubmission #{uid}"
      FailedSubmission.reprocess! uid, destination
    end
  end
end

