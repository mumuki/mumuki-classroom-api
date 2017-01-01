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
      Mumukit::Auth::Permissions.parse find_by(uid: uid).permissions.as_json
    end
  end

  def close
  end

  def clean_env!
  end

  private

  def mongo_collection_name
    :permissions
  end

end
