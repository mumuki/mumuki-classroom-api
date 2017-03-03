class Exercise

  include Mongoid::Document

  field :eid, type: Numeric
  field :number, type: Numeric
  field :name, type: String

end
