class Classroom::Collection::Students < Classroom::Collection::CourseCollection

  def find_by(args)
    first_by(args, { _id: -1 })
  end

end

class Classroom::StudentNotExistsError < StandardError
end
