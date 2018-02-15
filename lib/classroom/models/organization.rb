class Organization

  include Mongoid::Document
  include Mongoid::Timestamps

  field :id, type: Integer
  field :icon, type: String
  field :name, type: String
  field :locale, type: String
  field :book_id, type: Integer
  field :books, type: Array
  field :public, type: Mongoid::Boolean
  field :raise_hand_enabled, type: Mongoid::Boolean
  field :logo_url, type: String
  field :lock_json, type: Hash
  field :description, type: String
  field :contact_email, type: String
  field :socialBigButtons, type: Mongoid::Boolean
  field :disableResetAction, type: Mongoid::Boolean
  field :terms_of_service, type: String
  field :theme_stylesheet_url, type: String
  field :extension_javascript_url, type: String
  field :community_link, type: String
  field :login_methods, type: Array

  create_index({name: 1}, {unique: true})

  def login_method_present?(key, value)
    if lock_json.present?
      (lock_json['connections'] & [key, value]).present?
    else
      login_methods.include? key
      (login_methods & [key, value]).present?
    end
  end

  def self.find_by_name!(name)
    find_by! name: name
  end
end
