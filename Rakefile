require './lib/classroom'
require 'mumukit/nuntius'

namespace :submission do
  task :listen do
    Mumukit::Nuntius::Consumer.start "submissions" do |delivery_info, properties, body|
      data = JSON.parse(body)

      Classroom::Database.tenant = data.delete('tenant')

      begin
        Classroom::GuideProgress.update! data
      rescue Classroom::CourseStudentNotExistsError => e
        puts "Submission failed #{e}. Data was:"
        puts data
        Classroom::FailedSubmission.insert! data
      end
      Classroom::Database.client.close
    end
  end
end
