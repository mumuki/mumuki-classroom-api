class Mumukit::Auth::Profile
  attr_accessor :attributes

  FIELDS = [:uid, :social_id, :email, :name, :first_name, :last_name, :image_url]

  def initialize(attributes)
    @attributes = attributes
  end

  def self.extract(profile_like)
    new profile_like.as_json(only: FIELDS).with_indifferent_access
  end

  def ==(other)
    other.class == self.class && other.attributes == self.attributes
  end
end
