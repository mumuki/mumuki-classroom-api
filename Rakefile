require './lib/classroom'
require 'mumukit/nuntius'

namespace :submission do
  task :listen do
    Mumukit::Nuntius::Consumer.start "submissions" do |delivery_info, properties, body|
      data = JSON.parse JSON.parse(body).first
      Classroom::Database.tenant = data.delete('tenant')

      Classroom::GuideProgress.update! data

      Classroom::Database.client.close
    end
  end
end
