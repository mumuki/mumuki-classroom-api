class User

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mumukit::Platform::User::Helpers

  field :uid, type: String
  field :provider, type: String
  field :last_name, type: String
  field :first_name, type: String
  field :social_id, type: String
  field :email, type: String
  field :image_url, type: String
  field :permissions, type: Hash

  create_index({uid: 1}, {unique: true})

  validates :uid, presence: true

  def self.find_by_uid!(uid)
    find_by! uid: uid
  end

  def self.for_profile(profile)
    find_or_create_by!(uid: profile.uid).tap do |user|
      user.update_attributes! profile
    end
  end

  def self.upsert_permissions!(uid, permissions)
    user = find_or_create_by!(uid: uid)
    user.upsert_permissions! permissions
  end

  def upsert_permissions!(permissions)
    self.update! permissions: permissions.as_json
  end

  def permissions
    Mumukit::Auth::Permissions.parse self[:permissions]
  end
end
