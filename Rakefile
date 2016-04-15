require 'logger'

logger = Logger.new('/var/www/classroom-api/submissions-job.log')
logger.level = Logger::INFO

require './lib/classroom'
require 'mumukit/nuntius'

logger.info 'Listening to submissions'

namespace :submission do
  task :listen do
    Mumukit::Nuntius::Consumer.start 'submissions' do |delivery_info, properties, body|
      data = JSON.parse(body)

      Classroom::Database.tenant = data.delete('tenant')

      begin
        logger.info 'Processing new submission'
        Classroom::GuideProgress.update! data
      rescue Classroom::CourseStudentNotExistsError => e
        logger.warn "Submission failed #{e}. Data was: #{data}"
        Classroom::FailedSubmission.insert! data
      end
      Classroom::Database.client.close
    end
  end
end
