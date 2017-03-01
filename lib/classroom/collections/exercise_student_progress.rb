class Classroom::Collection::ExerciseStudentProgress < Classroom::Collection::CourseCollection

  def update!(exercise_student)
    mongo_collection.update_one(query_by_index(exercise_student), update_query(exercise_student), upsert: true)
  end

  def update_student!(sub_student)
    mongo_collection.update_many({'student.uid': sub_student[:'student.uid']}, {'$set': sub_student})
  end

  def stats(exercise_student)
    _stats(query_by_guide_and_student(exercise_student))
  end

  def all_stats(uid)
    _stats(student_query(uid))
  end

  def empty_stats
    {passed: 0,
     failed: 0,
     passed_with_warnings: 0}
  end

  def detach_student!(uid)
    mongo_collection.update_many(student_query(uid), '$set': {detached: true})
  end

  def attach_student!(uid)
    mongo_collection.update_many(student_query(uid), '$unset': {detached: ''})
  end

  def comment!(comment, sid)
    submissions[sid].push comments: comment
  end

  def wrap(it)
    inspection_wrap super(it)
  end

  def inspection_wrap(it)
    it.raw[:submissions].each do |submission|
      submission['expectation_results'].map! do |expectation|
        {html: Mumukit::Inspection::I18n.t(expectation), result: expectation['result']}
      end if submission['expectation_results'].present?
    end
    it
  end

  private

  def _stats(query)
    where(query)
      .as_json
      .deep_symbolize_keys[:exercise_student_progress]
      .map { |it| last_submission it }
      .group_by { |it| it[:status] }
      .reduce(empty_stats) { |json, (key, value)| json.tap { json[key] = value.size || 0 } }
      .deep_symbolize_keys
      .slice(*empty_stats.keys)
  end

  def last_submission(exercise_student)
    exercise_student[:submissions].max_by { |it| it[:created_at] }
  end

  def query_by_guide_and_student(exercise_student)
    query 'guide.slug': exercise_student[:guide][:slug], 'student.uid': exercise_student[:student][:uid]
  end

  def query_by_index(exercise_student)
    query_by_guide_and_student(exercise_student).merge 'exercise.id': exercise_student[:exercise][:id]
  end

  def update_query(exercise_student)
    {'$set': exercise_student.except(:submission), '$push': {submissions: exercise_student[:submission]}}
  end

  def student_query(uid)
    query 'student.uid': uid
  end

end
