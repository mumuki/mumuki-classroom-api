class Classroom::Collection::Teachers < Classroom::Collection::People

  def exists_exception
    Classroom::TeacherExistsError
  end

end


class Classroom::TeacherExistsError < StandardError
end

class Classroom::TeacherNotExistsError < StandardError
end
