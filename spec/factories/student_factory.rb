FactoryBot.define do
  factory :student, class: Mumuki::Classroom::Student do
    organization { Organization.current.name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
  end
end
