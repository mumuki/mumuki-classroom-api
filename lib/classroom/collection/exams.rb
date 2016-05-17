class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection


  def upsert!(data)
    update_one(
      { 'slug' => data['slug'], 'begin' => data['begin'], 'end' => data['end'], 'duration' => data['duration'] },
      { '$addToSet' => { 'social_ids' => { '$each' => data['social_ids'] }}},
      { :upsert => true })
  end

end
