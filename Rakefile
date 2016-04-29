
require './lib/classroom'
require 'mumukit/nuntius'

logger = Mumukit::Nuntius::Logger
logger.info 'Listening to submissions'

namespace :submission do
  task :listen do
    Mumukit::Nuntius::Consumer.start 'submissions' do |delivery_info, properties, body|
      begin
        data = JSON.parse(body)

        Classroom::Database.tenant = data.delete('tenant')

        begin
          logger.info 'Processing new submission'
          Classroom::Collection::GuidesProgress.update! data
        rescue => e
          logger.warn "Submission failed #{e}. Data was: #{data}"
          Classroom::Collection::FailedSubmissions.insert! data.wrap_json
        end
      rescue => e
        logger.error "Submission malformed #{e}. Data was: #{data}"
      ensure
        Classroom::Database.client.try(:close)
      end
    end
  end
end

