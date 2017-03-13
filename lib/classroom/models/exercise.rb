class Exercise

  include Mongoid::Document

  field :eid, type: Integer
  field :number, type: Integer
  field :name, type: String

end
