module Office
  module Event
    class UpsertOrganization
      def self.execute!(payload)
        organization = payload['organization']

        Classroom::Database.connect_transient! organization['name'] do
          Classroom::Collection::Organizations.upsert! organization
        end
      end
    end

    class OrganizationCreated < UpsertOrganization
    end

    class OrganizationChanged < UpsertOrganization
    end
  end
end
