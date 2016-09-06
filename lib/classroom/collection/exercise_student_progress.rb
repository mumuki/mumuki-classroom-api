class Classroom::Collection::ExerciseStudentProgress < Classroom::Collection::CourseCollection

  def update!(exercise_student)
    mongo_collection.update_one(query_by_index(exercise_student), update_query(exercise_student), upsert: true)
  end

  def stats(exercise_student)
    _stats(query_by_guide_and_student(exercise_student))
  end

  def all_stats(social_id)
    _stats(student_query(social_id))
  end

  def empty_stats
    { passed: 0,
      failed: 0,
      passed_with_warnings: 0 }
  end

  def delete_student!(social_id)
    where(student_query(social_id)).raw.each { |it| Classroom::FailedSubmission.from(it) }
    mongo_collection.delete_many(student_query(social_id))
  end

  def comment!(data)
    json = data.deep_symbolize_keys
    eid = json[:exercise_id]
    sid = json[:submission_id]
    social_id = json[:social_id]
    comment = json[:comment]
    mongo_collection.update_one(
      { :'student.social_id' => social_id, :'exercise.id' => eid, :'submissions.id' => sid },
      { :'$push' => { 'submissions.$.comments' => comment }}
    )

  end

  private

  def _stats(query)
    where(query)
      .as_json
      .deep_symbolize_keys[:exercise_student_progress]
      .map { |it| last_submission it }
      .group_by { |it| it[:status] }
      .reduce(empty_stats) { | json, (key, value)| json.tap { json[key] = value.size || 0 }}
      .deep_symbolize_keys
      .slice(*empty_stats.keys)
  end

  def last_submission(exercise_student)
    exercise_student[:submissions].max_by { |it| it[:created_at] }
  end

  def query_by_guide_and_student(exercise_student)
    { :'guide.slug' => exercise_student[:guide][:slug],
      :'student.social_id' => exercise_student[:student][:social_id] }
  end

  def query_by_index(exercise_student)
    query_by_guide_and_student(exercise_student).merge(:'exercise.id' => exercise_student[:exercise][:id])
  end

  def update_query(exercise_student)
    { :'$set' => exercise_student.except(:submission),
      :'$push' => { :submissions => exercise_student[:submission] }}
  end

  def student_query(social_id)
    {:'student.social_id' => social_id}
  end

end
