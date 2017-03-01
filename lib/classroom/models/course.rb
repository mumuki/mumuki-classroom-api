class Course

  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :slug, type: String
  field :name, type: String
  field :code, type: String
  field :days, type: Array
  field :shifts, type: Array
  field :period, type: String
  field :description, type: String
  field :organization, type: String

  scope :allowed, -> (grants_pattern) { where slug: {'$regex': "^#{grants_pattern}$"} }

  create_index({organization: 1, slug: 1}, {unique: true})

  def notify!
    Mumukit::Nuntius::EventPublisher.publish('CourseChanged', {course: self.as_json})
  end

  def self.ensure_new!(json)
    course = json.with_indifferent_access
    raise Classroom::CourseExistsError, "#{course[:slug]} does already exist" if already_exist? course
  end

  def self.ensure_exist!(json)
    course = json.with_indifferent_access
    raise Classroom::CourseNotExistsError, "#{course[:slug]} does not exist" unless already_exist? course
  end

  def self.already_exist?(course)
    find_by(organization: course[:organization], slug: course[:slug]).present?
  end

end
