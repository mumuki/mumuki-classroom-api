class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def upsert!(data)
    query = {'id' => data.delete('id')}
    update_one(
      query,
      {
        '$set' => data.except('social_ids'),
        '$addToSet' => { 'social_ids' => { '$each' => data['social_ids'] }}
      }
    )
    query
  end

  private

  def wrap(it)
    Mumukit::Service::JsonWrapper.new it
  end

end
