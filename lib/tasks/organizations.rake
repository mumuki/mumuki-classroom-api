namespace :organizations do
  task listen: :environment do
    Mumukit::Nuntius::EventConsumer.start 'office'
  end
end
