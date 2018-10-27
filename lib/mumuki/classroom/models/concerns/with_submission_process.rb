module WithSubmissionProcess
  def process!(data)
    json = data.deep_symbolize_keys

    json[:course] = find_submission_course! json
    json[:student] = find_student_from json

    update_guide json
    update_assignment json
    update_guide_progress json
    update_student_progress json
    update_student_last_assignment json
  end

  def organization(json)
    json[:organization]
  end

  def find_submission_course!(json)
    student = Student.last_updated_student_by(organization: organization(json), uid: uid(json))
    raise "Student not found" unless student
    student.course
  end

  def find_student_from(json)
    Student.find_by(organization: organization(json), course: course_slug(json), uid: uid(json)).as_json
  end

  def update_guide(json)
    organization = organization(json)
    course_slug = course_slug(json)
    slug = guide_from(json)[:slug]
    guide = Guide.find_or_create_by!(organization: organization, course: course_slug, slug: slug)
    guide.update_attributes!(guide_from json)
  end

  def update_student_progress(json)
    Student.find_by!(organization: organization(json), course: course_slug(json), uid: uid(json)).update_all_stats
  end

  def update_student_last_assignment(json)
    Student.find_by!(organization: organization(json), course: course_slug(json), uid: uid(json)).update_last_assignment_for
  end

  def update_assignment(json)
    assignment = Assignment
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
    GuideProgress
      .where(guide_progress_query(json))
      .first_or_create!(guide_progress_from json)
      .upsert_attributes(guide_progress_from json)
  end

  def student_stats_for(json)
    Assignment.stats_by guide_progress_query(json)
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
    student = json[:student]

    {uid: student[:uid],
     name: student[:name],
     email: student[:email],
     image_url: student[:image_url],
     social_id: student[:social_id],
     last_name: student[:last_name],
     first_name: student[:first_name]}.compact
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
    {sid: json[:sid],
     status: json[:status],
     result: json[:result],
     content: json[:content],
     feedback: json[:feedback],
     created_at: json[:created_at],
     test_results: json[:test_results],
     submissions_count: json[:submissions_count],
     expectation_results: json[:expectation_results]}.compact
  end
end
