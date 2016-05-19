class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def upsert!(data)
    query = {'id' => data.delete('id')}
    raise Classroom::ExamExistsError, 'Exam does not exist' unless any?(query)
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

class Classroom::ExamExistsError < StandardError
end
