class Message

  include Mongoid::Document

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :created_at, type: Time
  field :type, type: String
  field :date, type: String

  def content
    Mumukit::ContentType::Markdown.to_html(self[:content])
  end

end
