class Follower
  extend WithMongoIndex

  include Mongoid::Document
  include Mongoid::Timestamps
  include WithoutMongoId

  field :uids, type: Array
  field :email, type: String
  field :course, type: String
  field :organization, type: String

  create_index({organization: 1, course: 1, email: 1}, {unique: true})

  def add!(uid)
    self.add_to_set uids: uid
  end

  def remove!(uid)
    self.pull uids: uid
  end

end
