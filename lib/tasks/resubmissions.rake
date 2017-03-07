namespace :resubmissions do
  task :listen do
    Mumukit::Nuntius::Logger.info 'Listening to resubmissions'

    Mumukit::Nuntius::Consumer.negligent_start! 'resubmissions' do |body|
      begin
        destination = body['tenant']
        uid = body['uid']

        Mumukit::Nuntius::Logger.info "Processing resubmission #{uid}"
        Classroom::FailedSubmission.reprocess! uid, destination
      end
    end
  end
end

