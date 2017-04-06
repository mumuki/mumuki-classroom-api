module Classroom::Collection
  module Users
    extend Mumukit::Service::Collection

    def self.upsert_permissions!(uid, permissions)
      Classroom::Database.connect_transient! :classroom do
        upsert_attributes!({uid: uid}, {permissions: permissions.as_json})
      end
    end

    def self.find_by_uid!(uid)
      Classroom::Database.connect_transient! :classroom do
        find_by! uid: uid
      end
    end

    def self.find_by_uid(uid)
      Classroom::Database.connect_transient! :classroom do
        find_by uid: uid
      end
    end

    def self.for_profile(profile)
      Classroom::Database.connect_transient! :classroom do
        upsert_by! :uid, Classroom::User.new(profile)
        find_by_uid! profile.uid
      end
    end

    private

    def self.mongo_collection_name
      :permissions
    end

    def self.mongo_database
      Classroom::Database
    end

    def self.wrap(it)
      Classroom::User.new it
    end
  end
end
