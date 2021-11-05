module CourseMember
  extend ActiveSupport::Concern

  MANDATORY_FIELDS = %w(uid first_name last_name email)

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

    validates_presence_of(*MANDATORY_FIELDS)
    validates :email, email: true
  end

  def as_user(verified: true)
    member_json = as_json.merge_if(verified, validated_first_name: first_name, validated_last_name: last_name)
    User.whitelist_attributes member_json
  end

  class_methods do
    def valid_attributes?(json)
      MANDATORY_FIELDS.all? { |it| json[it].present? } && EmailValidator.valid?(json[:email])
    end

    def ensure_not_exists!(query)
      existing_members = where(query).where(detached: false)
      raise Mumuki::Classroom::CourseMemberExistsError, {existing_members: existing_members.map(&:uid)}.to_json if existing_members.exists?
    end

    def attributes_from_uid(uid)
      whitelist_attributes User.locate!(uid).to_resource_h
    end

    def create_from_json!(member_json)
      create! normalized_attributes_from_json(member_json)
    end

    def normalized_attributes_from_json(member_json)
      whitelist_attributes as_normalized_json(member_json)
    end

    def as_normalized_json(member = {})
      member.as_json.merge uid: (member[:uid] || member[:email])&.downcase,
                           email: member[:email]&.downcase,
                           last_name: member[:last_name]&.downcase&.titleize,
                           first_name: member[:first_name]&.downcase&.titleize
    end
  end
end

class Mumuki::Classroom::CourseMemberExistsError < Exception
end
