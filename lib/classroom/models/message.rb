class Message

  include Mongoid::Document

  field :sender, type: String
  field :email, type: String
  field :content, type: String
  field :created_at, type: Time
  field :type, type: String
  field :date, type: String

end
