class Classroom::PermissionsPersistence::Mongo

  include Mumukit::Service::Collection

  def self.from_env
    new
  end

  def set!(uid, permissions)
    Classroom::Database.with :classroom do
      update_one(
        { 'uid': uid },
        { '$set': { permissions: permissions } },
        { 'upsert': true }
      )
    end
  end

  def get(uid)
    Classroom::Database.with :classroom do
      permissions = find_by(uid: uid)&.permissions || {}
      Mumukit::Auth::Permissions.parse permissions.as_json
    end
  end

  def close
  end

  def clean_env!
  end

  private

  def mongo_database
    Classroom::Database
  end

  def mongo_collection_name
    :permissions
  end

end
