class Message

  include Mongoid::Document

  field :sender, type: String
  field :content, type: String
  field :created_at, type: Time

end
