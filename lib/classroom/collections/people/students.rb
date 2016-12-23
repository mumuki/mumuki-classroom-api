class Classroom::Collection::Students < Classroom::Collection::People

  def exists_exception
    Classroom::StudentExistsError
  end

  def update!(data)
    query = {uid:  data[:uid]}
    update_one(query, { '$set': { first_name: data[:first_name], last_name: data[:last_name] }})
  end

  def update_all_stats
    find_projection.each do |student|
      uid = student.deep_symbolize_keys[:uid]
      update_all_stats_for(uid)
    end
  end

  def detach!(uid)
    mongo_collection.update_one(
      { 'uid': uid },
      { '$set': { detached: true, detached_at: Time.now }}
    )
  end

  def attach!(uid)
    mongo_collection.update_one(
      { 'uid': uid },
      { '$unset': { detached: '', detached_at: '' }}
    )
  end

  def update_all_stats_for(uid)
    all_stats = Classroom::Collection::ExerciseStudentProgress.for(course).all_stats(uid)
    update_one({ uid: uid }, { :'$set' => { stats: all_stats }})
  end

  def update_last_assignment_for(uid)
    last_assignment = Classroom::Collection::GuideStudentsProgress.for(course).last_assignment_for(uid)
    update_one({ uid: uid }, { '$set': { last_assignment: last_assignment }})
  end

  def delete!(uid)
    delete_one(uid: uid)
    student = { 'student.uid': uid }
    Classroom::Collection::CourseStudents.delete_many(student.merge('course.slug': course_slug))
    Classroom::Collection::GuideStudentsProgress.for(course).delete_many(student)
    Classroom::Collection::ExerciseStudentProgress.for(course).delete_many(student)
    Classroom::Collection::Guides.for(course).delete_if_has_no_progress
  end

  def report(&block)
    all.raw.select(&block).as_json(only: [:first_name, :last_name, :email, :created_at])
  end

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end
