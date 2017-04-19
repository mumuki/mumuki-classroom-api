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

  create_index({organization: 1, slug: 1}, {unique: true})

  def notify!
    Mumukit::Nuntius.notify_event! 'CourseChanged', {course: self.as_json}
  end

  def self.allowed(organization, permissions)
    where(organization: organization).select { |course| permissions.has_permission? :teacher, course.uid }
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

  def self.import_from_json!(json)
    slug = json[:slug]
    json.delete(:organization_id)
    json[:organization] = Mumukit::Auth::Slug.parse(json[:slug]).organization
    Course.where(slug: slug).first_or_create.update_attributes(json.except(:subscription_mode))
  end

end

class Classroom::CourseExistsError < Exception
end

class Classroom::CourseNotExistsError < Exception
end