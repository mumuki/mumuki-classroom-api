class Classroom::Collection::Students < Classroom::Collection::People

  def exists_exception
    Classroom::StudentExistsError
  end

  def update!(data)
    update_one({uid: data[:uid]}, {'$set': data})
  end

  def update_all_stats
    find_projection.each do |student|
      uid = student.deep_symbolize_keys[:uid]
      update_all_stats_for(uid)
    end
  end

  def detach!(uid)
    do_detach!(uid)
    Classroom::Collection::ExerciseStudentProgress.for(organization, course).detach_student! uid
    Classroom::Collection::GuideStudentsProgress.for(organization, course).detach_student! uid
  end

  def attach!(uid)
    do_attach!(uid)
    Classroom::Collection::ExerciseStudentProgress.for(organization, course).attach_student! uid
    Classroom::Collection::GuideStudentsProgress.for(organization, course).attach_student! uid
  end

  def update_all_stats_for(uid)
    all_stats = Classroom::Collection::ExerciseStudentProgress.for(organization, course).all_stats(uid)
    update_one(query(uid: uid), {:'$set' => {stats: all_stats}})
  end

  def update_last_assignment_for(uid)
    last_assignment = Classroom::Collection::GuideStudentsProgress.for(organization, course).last_assignment_for(uid)
    update_one(query(uid: uid), {'$set': {last_assignment: last_assignment}})
  end

  def report(&block)
    all.raw.select(&block).as_json(only: [:first_name, :last_name, :email, :created_at, :detached_at])
  end

  def delete!(uid)
    delete_one(uid: uid)
    student = {'student.uid': uid}
    Classroom::Collection::CourseStudents.for(organization).delete_many(student.merge('course.slug': course_slug, organization: organization))
    Classroom::Collection::GuideStudentsProgress.for(organization, course).delete_many(student.merge(organization: organization))
    Classroom::Collection::ExerciseStudentProgress.for(organization, course).delete_many(student.merge(organization: organization))
    Guide.delete_if_has_no_progress(organization, course_slug)
  end


  private

  def do_detach!(uid)
    mongo_collection.update_one(
      query('uid': uid),
      {'$set': {detached: true, detached_at: Time.now}}
    )
  end

  def do_attach!(uid)
    mongo_collection.update_one(
      query('uid': uid),
      {'$unset': {detached: '', detached_at: ''}}
    )
  end

end

class Classroom::StudentExistsError < StandardError
end

class Classroom::StudentNotExistsError < StandardError
end
