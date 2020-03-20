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

  def self.bulk_permissions_update(users, role, course_slug)
    updated_users = users.map do |user|
      user.as_bulk_permissions_update(role, course_slug)
    end
    collection.bulk_write(updated_users)
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

end
