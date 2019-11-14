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

  def self.from_student_json(student_json)
    new student_json.except(:first_name, :last_name, :personal_id)
  end

  def self.bulk_permissions_update(users, role, course_slug)
    updated_users = users.map do |user|
      user.as_bulk_permissions_update(role, course_slug)
    end
    User.collection.bulk_write(updated_users)
  end

  def upsert_permissions!(permissions)
    self.update! permissions: permissions.as_json
  end

  def as_bulk_permissions_update(role, course_slug)
    add_permission!(role, course_slug)
    { update_one:
        {
          filter: { uid: uid },
          update: { :'$set' => {
            permissions: permissions.as_json
          }}
        }
    }

  end

  def add_permission!(role, course_slug)
    new_permissions = permissions
    new_permissions.add_permission!(role, course_slug)
    self.permissions = new_permissions.as_json
  end

  def permissions
    Mumukit::Auth::Permissions.parse self[:permissions]
  end
end
