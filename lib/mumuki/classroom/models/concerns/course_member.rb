module CourseMember
  extend ActiveSupport::Concern

  included do
    include Mongoid::Timestamps

    field :uid, type: String
    field :first_name, type: String
    field :last_name, type: String
    field :image_url, type: String
    field :name, type: String
    field :email, type: String
    field :social_id, type: String
    field :organization, type: String
    field :course, type: Mumukit::Auth::Slug

    create_index({organization: 1, course: 1, uid: 1}, {unique: true})
  end

  class_methods do
    def ensure_not_exists!(query)
      existing_members = where(query)
      return unless existing_members.exists?
      raise Mumuki::Classroom::CourseMemberExistsError, {existing_members: existing_members.map(&:uid)}.to_json
    end

    def attributes_from_user(uid)
      whitelist_attributes User.locate!(uid).to_resource_h
    end
  end
end

class Mumuki::Classroom::CourseMemberExistsError < Exception
end
