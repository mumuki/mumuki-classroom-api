helpers do
  def allowed_courses(permissions)
    allowed = Organization
                .locate!(organization)
                .courses
                .select { |course| permissions.has_permission? :teacher, course.slug }
                .map do |course|
                  course
                    .as_json(only: [:slug, :description, :period, :shifts, :days, :code])
                    .replace_key!('code', 'name')
                    .merge(organization: organization)
                end
    {courses: allowed.as_json}
  end

  def guide_progress_query
    with_detached_and_search with_organization_and_course('guide.slug': repo_slug), Mumuki::Classroom::GuideProgress
  end

  def student_query
    with_organization_and_course('guide.slug': repo_slug)
  end

  def student_assignment_query(student)
    student_info = student.slice('first_name', 'last_name', 'email').transform_keys { |it| "student.#{it}" }
    student_query.merge(student_info)
  end

  def course_report_projection
    {
      '_id': 0,
      'last_name': '$last_name',
      'first_name': '$first_name',
      'email': '$email',
      'personal_id': '$personal_id',
      'created_at': '$created_at',
      'last_submission_date': '$last_assignment.submission.created_at',
      'passed_count': '$stats.passed',
      'passed_with_warnings_count': '$stats.passed_with_warnings',
      'failed_count': '$stats.failed',
      'last_lesson_type': '$last_assignment.guide.parent.type',
      'last_lesson_name': '$last_assignment.guide.parent.name',
      'last_exercise_number': '$last_assignment.exercise.number',
      'last_exercise_name': '$last_assignment.exercise.name',
      'last_chapter': '$last_assignment.guide.parent.chapter.name',
    }
  end

  def guide_report_projection
    {
      '_id': 0,
      'last_name': '$student.last_name',
      'first_name': '$student.first_name',
      'email': '$student.email',
      'passed_count': '$stats.passed',
      'passed_with_warnings_count': '$stats.passed_with_warnings',
      'failed_count': '$stats.failed',
      'items_to_review': ''
    }
  end

  def csv_with_headers(csv, projection)
    headers = projection.symbolize_keys.except(:_id).keys.join(',')
    "#{headers}\n#{csv}"
  end

  def add_failed_tags(report_json, exercises)
    report_json.each do |student|
      items_to_review = Mumuki::Classroom::Assignment.items_to_review(student_assignment_query(student), exercises)
      student['items_to_review'] = items_to_review.join ', '
    end
  end

  def normalized_exercises
    json_body[:exercises].map do |it|
      {language: json_body[:language]}.merge(it.symbolize_keys)
    end
  end
end

Mumukit::Platform.map_organization_routes!(self) do
  get '/courses' do
    allowed_courses permissions
  end

  get '/api/courses' do
    allowed_courses permissions
  end

  post '/courses' do
    current_user.protect! :janitor, json_body[:slug]
    course = Course.create! with_organization(json_body).tap { |it| it['organization'] = Organization.locate!(it['organization']) }
    course.notify!
    {status: :created}
  end

  get '/courses/:course' do
    authorize! :teacher
    {course: Course.find_by!(with_organization slug: course_slug)}
  end

  post '/courses/:course/invitation' do
    authorize! :teacher
    course = Course.find_by! with_organization slug: course_slug
    {invitation: course.invite!(json_body[:expiration_date])}
  end

  get '/courses/:course/guides' do
    authorize! :teacher
    {guides: Mumuki::Classroom::Guide.where(with_organization_and_course).as_json}
  end

  get '/api/courses/:course/guides' do
    authorize! :teacher
    {guides: Mumuki::Classroom::Guide.where(with_organization_and_course).as_json}
  end

  get '/courses/:course/guides/:organization/:repository' do
    authorize! :teacher
    count, guide_progress = Sorting.aggregate(Mumuki::Classroom::GuideProgress, guide_progress_query, paginated_params, query_params)
    {
      total: count,
      page: page + 1,
      guide_students_progress: guide_progress
    }
  end

  post '/courses/:course/guides/:organization/:repository/report' do
    authorize! :teacher
    json = Reporting.aggregate(Mumuki::Classroom::GuideProgress, guide_progress_query, paginated_params, query_params, guide_report_projection).as_json
    add_failed_tags json, normalized_exercises
    content_type 'application/csv'
    csv_with_headers(Mumuki::Classroom::Reports::Formats.format_report('csv', json), guide_report_projection)
  end

  get '/courses/:course/guides/:organization/:repository/:uid' do
    authorize! :teacher
    {exercise_student_progress: Mumuki::Classroom::Assignment.with_full_messages(with_organization_and_course(exercise_student_progress_query), current_user)}
  end

  get '/courses/:course/progress' do
    authorize! :teacher
    {exercise_student_progress: Mumuki::Classroom::Assignment.where(with_organization_and_course).as_json}
  end

  get '/courses/:course/report' do
    authorize! :teacher
    aggregation = Mumuki::Classroom::Student.where(with_organization_and_course).project(course_report_projection)
    pipeline_with_sort_criterion = aggregation.pipeline << {'$sort': {passed_count: -1, passed_with_warnings_count: -1, failed_count: -1, last_name: 1, first_name: 1}}
    json = Mumuki::Classroom::Student.collection.aggregate(pipeline_with_sort_criterion).as_json
    content_type 'application/csv'
    csv_with_headers(Mumuki::Classroom::Reports::Formats.format_report('csv', json), course_report_projection)
  end

  get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
    Mumuki::Classroom::Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
  end
end
