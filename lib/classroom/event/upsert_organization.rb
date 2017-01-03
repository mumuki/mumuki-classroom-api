class Classroom::Event::UpsertOrganization
  class << self
    def execute!(organization)
      Classroom::Database.connect_transient! organization['name'] do
        Classroom::Collection::Organizations.upsert! organization
      end
    end
  end
end
