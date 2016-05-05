class Classroom::Collection::Guides < Classroom::Collection::CourseCollection

  private

  def wrap_array(it)
    Classroom::Collection::GuideArray.new(it)
  end

end
