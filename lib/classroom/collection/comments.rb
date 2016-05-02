class Classroom::Collection::Comments < Classroom::Collection::CourseCollection

  private

  def wrap_array(it)
    Classroom::Collection::CommentArray.new(it)
  end

end
