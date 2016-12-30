class Classroom::Collection::Teachers < Classroom::Collection::People

  def exists_exception
    Classroom::TeacherExistsError
  end

  def upsert!(teacher)
    mongo_collection.update_one(
      { 'uid': teacher[:uid] },
      { '$set': teacher },
      { 'upsert': true }
    )
  end

end


class Classroom::TeacherExistsError < StandardError
end

class Classroom::TeacherNotExistsError < StandardError
end
