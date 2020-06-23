namespace :classroom do
  namespace :resubmissions do
    task listen: :environment do
      Mumukit::Nuntius::Logger.info 'Listening to resubmissions'

      Mumukit::Nuntius::Consumer.negligent_start! 'resubmissions' do |body|
        destination = body['tenant']
        uid = body['uid']

        Mumukit::Nuntius::Logger.info "Processing resubmission #{uid}"
        Mumuki::Classroom::FailedSubmission.reprocess! uid, destination
      end
    end
  end
end
