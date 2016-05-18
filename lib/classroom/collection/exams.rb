class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def upsert!(data)
    query = {'id' => data['id']}
    json = data.except('id')
    puts("JSON: #{json}")
    puts("JSON: #{query}")
    puts("JSON: #{json['social_ids']}")
    puts("JSON: #{json.except('social_ids')}")
    update_one(
      query,
      {
        '$set' => json.except('social_ids'),
        '$addToSet' => { 'social_ids' => { '$each' => json['social_ids'] }}
      }
    )
    query
  end

  private

  def wrap(it)
    Mumukit::Service::JsonWrapper.new it
  end

end
