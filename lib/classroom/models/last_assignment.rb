class LastAssignment

  include Mongoid::Document

  embeds_one :guide
  embeds_one :exercise
  embeds_one :submission

end
