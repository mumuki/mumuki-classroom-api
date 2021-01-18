module WithSubmissionProcess
  def process!(data)
    json = data.deep_symbolize_keys

    json[:course] = find_submission_course! json
    json[:student] = find_student_from json

    update_assignment json
    update_guide_progress json
    update_student_progress json
    update_student_last_assignment json
  end

  def organization(json)
    json[:organization]
  end

  def find_submission_course!(json)
    student = Mumuki::Classroom::Student.last_updated_student_by(organization: organization(json), uid: uid(json))
    raise ActiveRecord::RecordNotFound, "Mumuki::Classroom::Student not found" unless student
    student.course
  end

  def find_student_from(json)
    Mumuki::Classroom::Student.find_by(organization: organization(json), course: course_slug(json), uid: uid(json))
  end

  def update_student_progress(json)
    Mumuki::Classroom::Student.find_by!(organization: organization(json), course: course_slug(json), uid: uid(json)).update_all_stats
  end

  def update_student_last_assignment(json)
    Mumuki::Classroom::Student.find_by!(organization: organization(json), course: course_slug(json), uid: uid(json)).update_last_assignment_for
  end

  def update_assignment(json)
    assignment = Mumuki::Classroom::Assignment
                   .where(assignment_query(json))
                   .first_or_create!(assignment_without_submission_from(json))
    assignment.upsert_attributes(assignment_without_submission_from(json))
    assignment.add_submission! submission_from(json)
  end

  def assignment_query(json)
    guide_progress_query(json).merge 'exercise.eid': exercise_from(json)[:eid]
  end

  def guide_progress_query(json)
    {'organization': organization(json),
     'course': course_slug(json),
     'guide.slug': guide_from(json)[:slug],
     'student.uid': uid(json)}
  end

  def update_guide_progress(json)
    json[:stats] = student_stats_for json
    Mumuki::Classroom::GuideProgress
      .where(guide_progress_query(json))
      .first_or_create!(guide_progress_from json)
      .upsert_attributes(guide_progress_from json)
  end

  def student_stats_for(json)
    Mumuki::Classroom::Assignment.stats_by guide_progress_query(json)
  end

  def uid(json)
    json[:submitter][:uid]
  end

  def course_slug(json)
    json[:course]
  end

  def guide_progress_from(json)
    {guide: guide_from(json),
     student: student_from(json),
     stats: stats_from(json),
     last_assignment: {exercise: exercise_from(json),
                       submission: submission_from(json)}}
  end

  def assignment_without_submission_from(json)
    {guide: guide_from(json),
     student: student_from(json),
     exercise: exercise_from(json)}
  end

  def assignment_from(json)
    assignment_without_submission_from.merge submission: submission_from(json)
  end

  def stats_from(json)
    stats = json[:stats]

    {passed: stats[:passed],
     failed: stats[:failed],
     passed_with_warnings: stats[:passed_with_warnings]}.compact
  end

  def student_from(json)
    json[:student].as_submission_json
  end

  def guide_from(json)
    guide = json[:guide]

    classroom_guide = {
      slug: guide[:slug],
      name: guide[:name],
      parent: guide[:parent],
      language: {
        name: guide[:language][:name],
        devicon: guide[:language][:devicon]
      }.compact
    }
    classroom_guide.compact
  end

  def exercise_from(json)
    exercise = json[:exercise]

    {eid: exercise[:eid],
     name: exercise[:name],
     number: exercise[:number]}.compact
  end

  def submission_from(json)
    Mumuki::Classroom::FailedSubmission.new(json).as_assignment_submission
  end
end
