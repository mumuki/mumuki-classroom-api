class Notification

  include Mongoid::Document
  include Mongoid::Timestamps

  field :organization, type: String
  field :course, type: String
  field :type, type: String
  field :read, type: Mongoid::Boolean, default: false
  field :sender, type: String

  belongs_to :assignment

  create_index({'organization': 1})
  create_index({'organization': 1, 'read': 1})

  def self.allowed(options, permissions)
    where(options).select {|notification| permissions.has_permission? :teacher, notification.course}.map(&:with_assignment)
  end

  def self.page(organization, permissions, page, per_page)
    where(organization: organization)
      .sort(created_at: :desc)
      .skip(per_page * (page - 1))
      .limit(per_page)
      .select {|notification| permissions.has_permission? :teacher, notification.course}
      .map(&:with_assignment)
  end

  def self.unread(organization, permissions)
    allowed({organization: organization, read: false}, permissions)
  end

  def self.import_from_json!(type, assignment)
    Notification.create! organization: assignment.organization,
                         course: assignment.course,
                         type: type,
                         sender: assignment.student[:uid],
                         assignment: assignment
  end

  def read!
    update! read: true
  end

  def unread!
    update! read: false
  end

  def with_assignment
    as_json.except('assignment_id').merge(assignment: assignment.notification_preview, id: id.to_s)
  end
end
