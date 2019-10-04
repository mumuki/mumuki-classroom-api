class Mumuki::Classroom::Teacher < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :image_url, type: String
  field :name, type: String
  field :email, type: String
  field :social_id, type: String
  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug

  create_index({organization: 1, course: 1, uid: 1}, {unique: true})

  def self.exists_exception
    Mumuki::Classroom::TeacherExistsError
  end

end


class Mumuki::Classroom::TeacherExistsError < StandardError
end

class Mumuki::Classroom::TeacherNotExistsError < StandardError
end
