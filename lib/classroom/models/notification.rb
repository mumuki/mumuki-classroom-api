class Notification

  include Mongoid::Document
  include Mongoid::Timestamps

  field :organization, type: String
  field :course, type: String
  field :type, type: String
  field :read, type: Mongoid::Boolean, default: false
  field :sender, type: String
  field :created_at, type: Time

  belongs_to :assignment

  create_index({'organization': 1})
  create_index({'organization': 1, 'read': 1})

  def self.allowed(options, permissions)
    where(options).select { |course| permissions.has_permission? :teacher, course }.map(&:with_assignment)
  end

  def self.unread(organization, permissions)
    allowed({organization: organization, read: false}, permissions)
  end

  def read!
    update! read: true
  end

  def with_assignment
    as_json.except('assignment_id').merge(assignment: assignment, id: id.to_s)
  end

end
