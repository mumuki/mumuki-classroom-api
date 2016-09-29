logger = Mumukit::Nuntius::Logger

namespace :resubmissions do
  task :listen do
    logger.info 'Listening to resubmissions'

    Mumukit::Nuntius::Consumer.start 'resubmissions' do |delivery_info, properties, body|
      begin
        destination = body.delete('tenant')
        social_id = body['social_id']

        logger.info "Processing resubmission #{social_id}"

        Classroom::FailedSubmission.reprocess! social_id, destination
      rescue => e
        logger.error "Resubmission couldn't be processed #{e}. it was: #{body}"
      ensure
        Classroom::Database.disconnect!
      end
    end
  end
end

