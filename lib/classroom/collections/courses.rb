class Classroom::Collection::Courses < Classroom::Collection::OrganizationCollection

  def allowed(grants_pattern)
    where(uid: {'$regex' => grants_pattern})
  end

  def ensure_new!(uid)
    raise Classroom::CourseExistsError, "#{uid} does already exist" if any?(uid: uid)
  end

  def ensure_exist!(uid)
    raise Classroom::CourseNotExistsError, "#{uid} does not exist" unless any?(uid: uid)
  end

  def upsert!(course)
    mongo_collection.update_one(
      {'uid': course[:uid]},
      {'$set': course.as_json(except: :uid)},
      {'upsert': true}
    )
  end

  private

  def pk
    super.merge({uid: 1})
  end

end


class Classroom::CourseExistsError < StandardError
end

class Classroom::CourseNotExistsError < StandardError
end
