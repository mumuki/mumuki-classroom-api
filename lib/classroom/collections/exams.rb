class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def update!(id, data)
    {id: id}.tap do |query|
      verify_exam_exists id
      update_one(query, {'$set' => data})
    end
  end

  def add_student!(id, uid)
    {id: id}.tap do |query|
      verify_exam_exists id
      update_one(query, {'$addToSet': {uids: uid}})
    end
  end

  private

  def verify_exam_exists(id)
    raise Classroom::ExamExistsError, 'Exam does not exist' unless exists?(id)
  end

  def wrap(it)
    Mumukit::Service::JsonWrapper.new it
  end

end

class Classroom::ExamExistsError < StandardError
end
