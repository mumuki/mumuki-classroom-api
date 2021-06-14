namespace :classroom do
  namespace :user_permissions do
    task listen: :environment do
      Mumukit::Nuntius::Logger.info 'Listening to student user_permissions_changed'

      Mumukit::Nuntius::Consumer.negligent_start! 'user-permissions-changed' do |body|
        ApplicationRecord.with_pg_retry do
          user = body[:user]
          Mumukit::Nuntius::Logger.info "Processing user #{user}"
          Mumuki::Classroom::Event::UserChanged.execute!(user)
        end
      rescue => e
        Mumukit::Nuntius::Logger.warn "Mumuki::Classroom::UserChanged failed #{e}. body was: #{body}"
      end
    end
  end
end
