require './lib/classroom'
require 'mumukit/auth'
require 'mumukit/nuntius'

logger = Mumukit::Nuntius::Logger

namespace :submission do
  task :listen do
    logger.info 'Listening to submissions'

    Mumukit::Nuntius::Consumer.start 'submissions' do |delivery_info, properties, body|
      begin
        Classroom::Database.connect! body.delete('tenant')

        begin
          logger.info "Processing submission #{body['id']}"
          Classroom::Submission.process! body
        rescue => e
          logger.warn "Submission failed #{e}. body was: #{body}"
          Classroom::Collection::FailedSubmissions.insert! body.wrap_json
        end
      rescue => e
        logger.error "Submission couldn't be processed #{e}. body was: #{body}"
      ensure
        Classroom::Database.disconnect!
      end
    end
  end
end


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

