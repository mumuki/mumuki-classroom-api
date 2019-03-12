class Organization

  include Mongoid::Document
  include Mongoid::Timestamps
  # Warning: if you want to update organization settings, theme or profile,
  # you must replace them instead of mutating them
  include Mumukit::Platform::Organization::Helpers

  field :id, type: Integer
  field :name, type: String
  field :book, type: Mumukit::Auth::Slug

  field :profile,  type: Mumukit::Platform::Organization::Profile,  default: Mumukit::Platform::Organization::Profile.new
  field :theme,    type: Mumukit::Platform::Organization::Theme,    default: Mumukit::Platform::Organization::Theme.new
  field :settings, type: Mumukit::Platform::Organization::Settings, default: Mumukit::Platform::Organization::Settings.new

  create_index({name: 1}, {unique: true})

  def self.find_by_name!(name)
    find_by! name: name
  end

  def self.import_from_json!(json)
    json = Mumukit::Platform::Organization::Helpers.slice_platform_json json
    Organization.where(name: json[:name]).first_or_create.update_attributes(json)
  end
end

class Classroom::OrganizationNotExistsError < Exception
end
