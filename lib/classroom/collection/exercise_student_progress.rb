class Classroom::Collection::ExerciseStudentProgress < Classroom::Collection::CourseCollection

  def update!(exercise_student)
    mongo_collection.update_one(query_by_index(exercise_student), update_query(exercise_student), upsert: true)
  end

  def stats(exercise_student)
    where(query_by_guide_and_student(exercise_student))
      .as_json
      .deep_symbolize_keys[:exercise_student_progress]
      .map { |it| last_submission it }
      .group_by { |it| it[:status] }
      .reduce(empty_stats) { | json, (key, value)| json.tap { json[key] = value.size || 0 }}
      .deep_symbolize_keys
  end

  def empty_stats
    { passed: 0,
      failed: 0,
      passed_with_warnings: 0 }
  end

  private

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

end
