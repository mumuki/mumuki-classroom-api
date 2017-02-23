class Organization
  extend WithMongoIndex

  include Mongoid::Document
  include Mongoid::Timestamps
  include WithoutMongoId

  field :id, type: Numeric
  field :icon, type: String
  field :name, type: String
  field :locale, type: String
  field :book_id, type: Numeric
  field :private, type: Mongoid::Boolean
  field :logo_url, type: String
  field :lock_json, type: Hash
  field :description, type: String
  field :contact_email, type: String
  field :socialBigButtons, type: Mongoid::Boolean
  field :disableResetAction, type: Mongoid::Boolean

  create_index({name: 1}, {unique: true})

end
