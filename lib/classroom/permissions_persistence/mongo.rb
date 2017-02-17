class Classroom::PermissionsPersistence::Mongo

  include Mumukit::Service::Collection

  def self.from_config
    new
  end

  def set!(uid, permissions)
    Classroom::Database.connect!
    update_one(
      {'uid': uid},
      {'$set': {permissions: permissions.as_json}},
      {'upsert': true}
    )
  end

  def get(uid)
    Classroom::Database.connect!
    permissions = find_by(uid: uid)&.permissions || {}
    Mumukit::Auth::Permissions.parse permissions.as_json
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
