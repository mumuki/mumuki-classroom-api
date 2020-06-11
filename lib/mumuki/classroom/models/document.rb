class Mumuki::Classroom::Document

  def self.whitelist_attributes(json)
    json.with_indifferent_access.except(:created_at, :updated_at, :_id).slice(*attribute_names)
  end

  def self.inherited(subclass)
    super
    subclass.include Mongoid::Document
    subclass.store_in collection: subclass.name.demodulize.tableize
  end
end
