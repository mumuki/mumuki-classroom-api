require './lib/classroom'
require 'mumukit/nuntius'

logger = Mumukit::Nuntius::Logger
logger.info 'Listening to submissions'

namespace :submission do
  task :listen do
    Mumukit::Nuntius::Consumer.start 'submissions' do |delivery_info, properties, body|
      begin
        Classroom::Database.tenant = body.delete('tenant')

        begin
          logger.info "Processing submission #{body['id']}"
          Classroom::Collection::GuidesProgress.update! body
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
