class Classroom::Collection::Students < Classroom::Collection::CourseCollection

  def find_by(args)
    first_by(args, { _id: -1 })
  end

  def ensure_new!(social_id)
    raise Classroom::StudentExistsError, 'Student already exist' if any?('student.social_id' => social_id)
  end

  private

  def wrap_array(it)
    Classroom::Collection::StudentArray.new(it)
  end

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end
