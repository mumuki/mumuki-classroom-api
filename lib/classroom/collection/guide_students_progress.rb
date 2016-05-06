class Classroom::Collection::GuideStudentsProgress < Classroom::Collection::CourseCollection

  private

  def wrap_array(it)
    Classroom::Collection::GuideStudentsProgressArray.new(it)
  end

end
