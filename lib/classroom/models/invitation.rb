class Invitation

  include Mongoid::Document

  field :code, type: String, default: -> { Invitation.generate_code }
  field :course_slug, type: String
  field :expiration_date, type: Time
  belongs_to :course

  before_validation :check_if_expired!

  def check_if_expired!
    if expired?
      raise Exception.new "Must be in future"
    end
  end

  def as_json(option={})
    {code: code, course: course_slug, expiration_date: expiration_date}
  end

  def expired?
    Time.now > expiration_date
  end

  def self.generate_code
    SecureRandom.urlsafe_base64 4
  end

end
