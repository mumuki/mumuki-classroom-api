class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def upsert!(data)
    update_one(
      { 'slug' => data['slug']},
      {
        '$set' => data.except('social_ids'),
        '$addToSet' => { 'social_ids' => { '$each' => data['social_ids'] }}
      }
    )
  end

  private

  def wrap(it)
    Mumukit::Service::JsonWrapper.new it
  end

end
