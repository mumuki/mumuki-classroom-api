class Classroom::Collection::ExerciseStudentProgress < Classroom::Collection::CourseCollection

  private

  def wrap_array(it)
    Classroom::Collection::ExerciseStudentProgressArray.new(it)
  end

end
