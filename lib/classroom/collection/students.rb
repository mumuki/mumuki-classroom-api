class Classroom::Collection::Students < Classroom::Collection::CourseCollection

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


  def ensure_new!(social_id)
    raise Classroom::StudentExistsError, 'Student already exist' if any?(social_id: social_id)
  end

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end
