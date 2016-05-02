class Classroom::Collection::CourseStudents < Classroom::Collection::CourseCollection

  def find_by(args)
    first_by(args, { _id: -1 })
  end

end

class Classroom::CourseStudentNotExistsError < StandardError
end
