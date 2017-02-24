class User
  extend WithMongoIndex

  include Mongoid::Document
  include Mongoid::Timestamps
  include WithoutMongoId
  include Mumukit::Login::UserPermissionsHelpers

  field :uid, type: String
  field :provider, type: String
  field :name, type: String
  field :social_id, type: String
  field :email, type: String
  field :image_url, type: String
  field :permissions, type: Mumukit::Auth::Permissions

  create_index({uid: 1}, {unique: true})

  def self.find_by_uid!(uid)
    find_by! uid: uid
  end

  def self.for_profile(profile)
    find_or_create_by!(uid: profile.uid).tap do |user|
      user.update_attributes! profile
    end
  end

  def self.upsert_permissions!(uid, permissions)
    find_or_create_by!(uid: uid).update_attributes! permissions: permissions.as_json
  end

  def permissions
    Mumukit::Auth::Permissions.parse self[:permissions]
  end

end
