class Classroom::Collection::Comments < Classroom::Collection::CourseCollection

  private

  def mongo_collection_name
    underscore_class_name.to_sym
  end

  def wrap_array(it)
    Classroom::Collection::CommentArray.new(it)
  end

end
