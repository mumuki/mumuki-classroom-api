class Mumuki::Classroom::Guide < Mumuki::Classroom::Document
  include Mongoid::Timestamps

  field :slug, type: Mumukit::Auth::Slug
  field :name, type: String
  field :course, type: Mumukit::Auth::Slug
  field :parent, type: Hash
  field :language, type: Hash
  field :organization, type: String

  create_index({organization: 1, course: 1, slug: 1}, {unique: true})

  def self.delete_if_has_no_progress(organization, course_slug)
    where(organization: organization, course: course_slug).each do |guide|
      unless Mumuki::Classroom::GuideProgress.find_by(organization: guide.organization, course: guide.course, 'guide.slug': guide.slug)
        guide.destroy
      end
    end
  end

  def course_name
    course.to_mumukit_slug.course
  end

  def transfer(destination)
    update_attributes! slug: destination
  end

end
