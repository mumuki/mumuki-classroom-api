class Classroom::PermissionsPersistence::Mongo

  def self.from_config
    new
  end

  def set!(uid, permissions)
    User.upsert_permissions! uid, permissions
  end

  def get(uid)
    User.find_by_uid!(uid).permissions
  rescue Mongoid::Errors::DocumentNotFound => _
    {}
  end

  def close
  end

  def clean_env!
  end

end
