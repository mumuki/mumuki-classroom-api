class Classroom::Collection::People < Classroom::Collection::CourseCollection

  def find_by(args)
    first_by(args, { _id: -1 })
  end

  def wrap(it)
    date_wrap super(it)
  end

  def date_wrap(it)
    it.raw.delete(:_id)
    it
  end

  def find_projection(args={}, projection={})
    mongo_collection.find(args).projection(projection)
  end


  def ensure_new!(social_id, email)
    raise exists_exception, "#{underscore_class_name.capitalize.singularize} already exist" if any?('$or' => [{social_id: social_id}, {email: email}])
  end

end

