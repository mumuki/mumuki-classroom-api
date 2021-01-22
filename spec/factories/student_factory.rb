FactoryBot.define do
  factory :student, class: Mumuki::Classroom::Student do
    organization { Organization.current.name }
  end
end
