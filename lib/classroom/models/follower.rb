class Follower

  include Mongoid::Document

  field :uids, type: Array
  field :email, type: String
  field :course, type: String
  field :organization, type: String

  index organization: 1, course: 1, email: 1

  def add!(uid)
    self.add_to_set uids: uid
  end

  def remove!(uid)
    self.pull uids: uid
  end

  def as_json(options = {})
    super options.merge(except: :_id)
  end

end
