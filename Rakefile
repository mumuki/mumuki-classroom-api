require './lib/classroom'
require 'mumukit/auth'
require 'mumukit/nuntius'

logger = Mumukit::Nuntius::Logger

namespace :submission do
  task :listen do
    logger.info 'Listening to submissions'

    Mumukit::Nuntius::Consumer.start 'submissions' do |delivery_info, properties, body|
      begin
        Classroom::Database.tenant = body.delete('tenant')

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

namespace :users do
  task :update_metadata, [:tenant] do |t, args|
    auth0 = Auth0Client.new(
      :client_id => ENV['MUMUKI_AUTH0_CLIENT_ID'],
      :client_secret => ENV['MUMUKI_AUTH0_CLIENT_SECRET'],
      :domain => "mumuki.auth0.com"
    )

    Classroom::Database.tenant = args[:tenant]
    social_ids = Classroom::CourseStudent.distinct('student.social_id')
    social_ids.each do |sid|
      Mumukit::Auth::User.new(sid).update_permissions('atheneum', "#{args[:tenant]}/*")
    end
  end
end

namespace :students do
  task :progress do |t, args|
    Classroom::Database.tenant = :test
    Classroom::Database.within_each do
      Classroom::Collection::Courses.all.raw.each do |course|
        course_slug_code = course.slug.split('/').second
        Classroom::Collection::Students.for(course_slug_code).update_all_stats
      end
    end
  end
  task :teacherify_all do
    Classroom::Database.tenant = :test
    Classroom::Database.within_each do
      Classroom::Collection::CourseStudents.all.raw.each do |course_student|
        student = course_student.student.deep_symbolize_keys
        course_slug = course_student.course.deep_symbolize_keys[:slug]
        course_slug_code = course_slug.split('/').second

        begin
          user = Mumukit::Auth::User.new(student[:social_id])

          if student[:email].present? && user.teacher?(course_slug)
            Classroom::Collection::Teachers.for(course_slug_code).upsert! student
          end
        rescue Auth0::NotFound => _
          logger.error "Auth0 User Not Found - Student: #{student}"
        end

      end
    end
  end
end
