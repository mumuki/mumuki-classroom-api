class Classroom::Collection::Exams < Classroom::Collection::CourseCollection

  include Mumukit::Service::Collection

  def initialize(organization, course)
    super organization, course
  end

  def update!(id, data)
    {id: id}.tap do |query|
      verify_exam_exists id
      update_one(query, {'$set' => query(data)})
    end
  end

  def add_student!(id, uid)
    {id: id}.tap do |query|
      verify_exam_exists id
      update_one(query, {'$addToSet': {uids: uid}})
    end
  end

  private

  def pk
    super.merge id: 1
  end

  def verify_exam_exists(id)
    raise Classroom::ExamExistsError, 'Exam does not exist' unless exists?(id)
  end

  def wrap(it)
    Mumukit::Service::JsonWrapper.new it
  end

end

class Classroom::ExamExistsError < StandardError
end
