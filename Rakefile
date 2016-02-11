require './lib/classroom'
require 'mumukit/auth'
require 'mumukit/nuntius'

logger = Mumukit::Nuntius::Logger

namespace :submission do
  task :listen do
    logger.info 'Listening to submissions'

    Mumukit::Nuntius::Consumer.start 'submissions' do |delivery_info, properties, body|
      begin
        Classroom::Database.organization = body.delete('tenant')

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
        Classroom::Database.client.try(:close)
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
        Classroom::Database.client.try(:close)
      end
    end
  end
end

namespace :guides do
  task :migrate_parent do
    logger.info 'Migrating guides'

    Classroom::Database.organization = :test
    Classroom::Database.within_each do
      Classroom::Collection::Courses.all.raw.each do | course |
        course_slug_code = course.slug.split('/').second
        Classroom::Collection::Guides.for(course_slug_code).all.raw.each do | guide |
          begin
            Classroom::Collection::Guides.for(course_slug_code).migrate_parent(guide)
          rescue => e
            logger.error e.message
          end
        end
      end
    end
  end
end

namespace :students do
  task :update_last_submission do
    Classroom::Database.organization = :test
    Classroom::Database.within_each do
      begin
        Classroom::Collection::Courses.all.raw.each do | course |
          course_slug_code = course.slug.split('/').second
          Classroom::Collection::Students.for(course_slug_code).all.raw.each do | student |
            Classroom::Collection::Students.for(course_slug_code).update_last_assignment_for(student.social_id)
          end
        end
      rescue => e
        puts e
      end
    end
  end
end
