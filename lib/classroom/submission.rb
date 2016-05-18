module Classroom::Submission

  def self.process!(data)
    json = data.deep_symbolize_keys

    json[:course] = find_submission_course! json
    json[:student] = find_student_from json

    update_guide json
    update_exercise_student_progress json
    update_guide_student_progress_with_stats json
  end

  def self.find_submission_course!(json)
    Classroom::Collection::CourseStudents
      .find_by_social_id!(social_id json)
      .course
      .deep_symbolize_keys
  end

  def self.find_student_from(json)
    Classroom::Collection::Students
      .for(course_prefix json)
      .find_by(social_id: social_id(json))
      .as_json
      .deep_symbolize_keys
  end

  def self.update_guide(json)
    Classroom::Collection::Guides
      .for(course_prefix json)
      .update!(guide_from json)
  end

  def self.update_exercise_student_progress(json)
    Classroom::Collection::ExerciseStudentProgress
      .for(course_prefix json)
      .update!(exercise_student_progress_from json)
  end

  def self.update_guide_student_progress_with_stats(json)
    json[:stats] = student_stats_for json
    update_guide_student_progress json
  end

  def self.update_guide_student_progress(json)
    Classroom::Collection::GuideStudentsProgress
      .for(course_prefix json)
      .update!(guide_students_progress_from json)
  end

  def self.student_stats_for(json)
    Classroom::Collection::ExerciseStudentProgress
      .for(course_prefix json)
      .stats(exercise_student_progress_from json)
      .deep_symbolize_keys
  end

  def self.social_id(json)
    json[:submitter][:social_id]
  end

  def self.course_prefix(json)
    json[:course][:slug].split('/').second
  end

  def self.guide_students_progress_from(json)
    { guide: guide_from(json),
      student: student_from(json),
      stats: stats_from(json),
      last_assignment: { exercise: exercise_from(json),
                         submission: submission_from(json) }}
  end

  def self.exercise_student_progress_from(json)
    { guide: guide_from(json),
      student: student_from(json),
      exercise: exercise_from(json),
      submission: submission_from(json) }
  end

  def self.stats_from(json)
    stats = json[:stats]

    { passed: stats[:passed],
      failed: stats[:failed],
      passed_with_warnings: stats[:passed_with_warnings] }
  end

  def self.student_from(json)
    student = json[:student]

    { name: student[:name],
      email: student[:email],
      image_url: student[:image_url],
      social_id: student[:social_id],
      last_name: student[:last_name],
      first_name: student[:first_name] }
  end

  def self.guide_from(json)
    guide = json[:guide]

    classroom_guide = {
      slug: guide[:slug],
      name: guide[:name],
      language: {
        name: guide[:language][:name],
        devicon: guide[:language][:devicon]
      }
    }
    classroom_guide[:lesson] = { id: guide[:chapter][:id], name: guide[:chapter][:name] } if guide[:chapter]
    classroom_guide
  end

  def self.exercise_from(json)
    exercise = json[:exercise]

    { id: exercise[:id],
      name: exercise[:name],
      number: exercise[:number] }
  end

  def self.submission_from(json)
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
