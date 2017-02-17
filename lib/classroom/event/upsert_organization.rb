module Classroom
  module Event
    class UpsertOrganization
      def self.execute!(payload)
        organization = payload['organization']

        Classroom::Database.connect!
        Classroom::Collection::Organizations.upsert! organization
      end
    end

    class OrganizationCreated < UpsertOrganization
    end

    class OrganizationChanged < UpsertOrganization
    end
  end
end
