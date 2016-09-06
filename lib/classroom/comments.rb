class Classroom::Comments

  def self.for(course, data)
    Classroom::Collection::ExerciseStudentProgress
      .for(course)
      .comment!(data)
  end

end
