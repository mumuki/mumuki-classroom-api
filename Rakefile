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

namespace :students do
  task :remove_teachers_student do
    begin
      Classroom::Database.tenant = :test
      Classroom::Database.within_each do
        total_students_count = Classroom::Collection::CourseStudents.count
        Classroom::Collection::CourseStudents.all.raw.each_with_index do |course_student, index|
          puts "Proccesing: #{index} of #{total_students_count} ----- # "
          student = course_student.student.deep_symbolize_keys
          course_slug = course_student.course.deep_symbolize_keys[:slug]
          course_slug_code = course_slug.split('/').second
          if Classroom::Collection::Teachers.for(course_slug_code).any?(social_id: student[:social_id])
            Classroom::Collection::Students.for(course_slug_code).delete_one(social_id: student[:social_id])
            Classroom::Collection::GuideStudentsProgress.for(course_slug_code).delete_many('student.social_id' => student[:social_id])
            Classroom::Collection::ExerciseStudentProgress.for(course_slug_code).delete_many('student.social_id' => student[:social_id])
            Classroom::Collection::CourseStudents.delete_many('student.social_id' => student[:social_id])
          end
        end
      end
    rescue Exception => e
      puts e
    end
  end
end

