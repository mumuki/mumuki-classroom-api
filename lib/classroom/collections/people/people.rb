class Classroom::Collection::People < Classroom::Collection::CourseCollection

  def find_by(args)
    first_by(args, { _id: -1 })
  end

  def wrap(it)
    date_wrap super(it)
  end

  def date_wrap(it)
    it.raw[:created_at] = it.raw.delete(:_id).generation_time
    it
  end

  def find_projection(args={}, projection={})
    mongo_collection.find(args).projection(projection)
  end

  def exists?(uid)
    any? uid: uid
  end

  def ensure_new!(uid)
    raise exists_exception, "#{underscore_class_name.capitalize.singularize} already exist" if exists? uid
  end

end

