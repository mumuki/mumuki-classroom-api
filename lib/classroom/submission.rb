module Classroom::Submission

  def process!(data)
    json = data.deep_symbolize_keys

    json[:course] = find_submission_course! json
    json[:student] = find_student_from json

    update_guide_students_progress json
    update_exercise_student_progress json
  end

  def find_submission_course!(json)
    CourseStudents.find_by_social_id!(social_id json).course
  end

  def update_guide_students_progress(json)
    GuideStudentsProgress.for(course_prefix json).update!(guide_students_progress_from json)
  end

  def update_exercise_student_progress(json)
    ExerciseStudentProgress.for(course_prefix json).update!(exercise_student_progress_from json)
  end

  def find_student_from(json)
    Students.for(course_prefix json).find_by(social_id: social_id json).as_json
  end

  def social_id(json)
    json[:submitter][:social_id]
  end

  def course_prefix(json)
    json[:course][:slug].split('/').second
  end

  def guide_students_progress_from(json)
    { guide: guide_from(json),
      student: student_from(json),
      last_assignment: { exercise: exercise_from(json),
                         submission: submission_from(json) }}
  end

  def exercise_student_progress_from(json)
    { guide: guide_from(json),
      student: student_from(json),
      exercise: exercise_from(json),
      submission: submission_from(json) }
  end

  def student_from(json)
    { name: json[:student][:name],
      email: json[:student][:email],
      image_url: json[:student][:image_url],
      social_id: json[:student][:social_id],
      last_name: json[:student][:last_name],
      first_name: json[:student][:first_name] }
  end

  def guide_from(json)
    { slug: json[:guide][:slug],
      name: json[:guide][:name],
      lesson: { id: json[:guide][:chapter][:id],
                name: json[:guide][:chapter][:name] },
      language: { name: json[:guide][:language][:name],
                  devicon: json[:guide][:language][:devicon] }}
  end

  def exercise_from(json)
    { id: json[:exercise][:id],
      name: json[:exercise][:name],
      number: json[:exercise][:number] }
  end

  def submission_from(json)
    { id: json[:id],
      status: json[:status],
      result: json[:result],
      content: json[:content],
      feedback: json[:feedback],
      created_at: json[:created_at],
      test_results: json[:test_results],
      submissions_count: json[:submissions_count],
      expectation_results: json[:expectation_results] }
  end

end
