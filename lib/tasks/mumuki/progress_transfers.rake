namespace :classroom do
  namespace :progress_transfers do
    task listen: :environment do
      Mumukit::Nuntius::Logger.info 'Listening to student progress-transfers'

      Mumukit::Nuntius::Consumer.negligent_start! 'progress-transfers' do |body|
        begin
          Mumuki::Classroom::Event::ProgressTransfer.new(body).execute!

          Mumukit::Nuntius::Logger.info "Processing progress transfer #{body[:item_id]}"
        rescue => e
          Mumukit::Nuntius::Logger.warn "Mumuki::Classroom::ProgressTransfer failed #{e}. body was: #{body}"
        end
      end
    end
  end
end
