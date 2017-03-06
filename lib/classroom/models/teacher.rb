class Teacher

  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :email, type: String
  field :social_id, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :image_url, type: String
  field :course, type: String
  field :organization, type: String

  create_index({organization: 1, course: 1, uid: 1}, {unique: true})

  def self.exists_exception
    Classroom::TeacherExistsError
  end

end


class Classroom::TeacherExistsError < StandardError
end

class Classroom::TeacherNotExistsError < StandardError
end
