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
    where(uid: profile.uid).first_or_create.tap do |user|
      user.update_attributes! profile
    end
  end

  def permissions
    Mumukit::Auth::Permissions.parse self[:permissions]
  end

end
