namespace :events do
  task listen: :environment do
    Mumukit::Nuntius::EventConsumer.start!
  end
end
