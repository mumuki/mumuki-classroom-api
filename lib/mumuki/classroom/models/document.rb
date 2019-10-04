class Mumuki::Classroom::Document

  def self.inherited(subclass)
    super
    subclass.include Mongoid::Document
    subclass.store_in collection: subclass.name.demodulize.tableize
  end
end
