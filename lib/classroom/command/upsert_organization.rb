class Classroom::Command::UpsertOrganization
  class << self
    def execute!(organization)
      Classroom::Database.with organization['name'] do
        Classroom::Collection::Organizations.upsert! organization
      end
    end
  end
end
