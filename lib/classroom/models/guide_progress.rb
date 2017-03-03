class GuideProgress

  include Mongoid::Document
  include Mongoid::Timestamps

  field :organization, type: String
  field :course, type: Mumukit::Auth::Slug
  field :stats, type: Hash

  embeds_one :guide
  embeds_one :student
  embeds_one :last_assignment

  store_in collection: 'guide_students_progress'
  create_index({'organization': 1, 'course': 1, 'guide.slug': 1, 'student.uid': 1})

end
