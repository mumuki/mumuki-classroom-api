module Classroom
  module Event
    class UpsertOrganization
      def self.execute!(payload)
        organization = payload['organization']
        Organization.find_or_create_by!(name: organization[:name]).update_attributes! organization
      end
    end

    class OrganizationCreated < UpsertOrganization
    end

    class OrganizationChanged < UpsertOrganization
    end
  end
end
