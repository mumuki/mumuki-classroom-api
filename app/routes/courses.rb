helpers do
  def allowed_courses(permissions)
    {courses: Course.allowed(organization, permissions).as_json}
  end

  def guide_progress_query
    with_detached_and_search with_organization_and_course('guide.slug': repo_slug)
  end

  def projection
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

  def csv_with_headers(csv)
    headers = projection.symbolize_keys.except(:_id).keys.join(',')
    "#{headers}\n#{csv}"
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
    course = Course.create! with_organization(json_body.merge uid: json_body[:slug])
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
    {invitation: course.invitation_link!(json_body[:expiration_date])}
  end

  get '/courses/:course/guides' do
    authorize! :teacher
    {guides: Guide.where(with_organization_and_course).as_json}
  end

  get '/api/courses/:course/guides' do
    authorize! :teacher
    {guides: Guide.where(with_organization_and_course).as_json}
  end

  get '/courses/:course/guides/:organization/:repository' do
    authorize! :teacher
    count, guide_progress = Sorting.aggregate(GuideProgress, guide_progress_query, paginated_params)
    {
      total: count,
      page: page + 1,
      guide_students_progress: guide_progress
    }
  end

  get '/courses/:course/guides/:organization/:repository/:uid' do
    authorize! :teacher
    {exercise_student_progress: Assignment.with_full_messages(with_organization_and_course(exercise_student_progress_query), current_user)}
  end

  get '/courses/:course/progress' do
    authorize! :teacher
    {exercise_student_progress: Assignment.where(with_organization_and_course).as_json}
  end

  get '/courses/:course/report' do
    aggregation = Student.where(with_organization_and_course).project(projection)
    pipeline_with_sort_criterion = aggregation.pipeline << {'$sort': {passed_count: -1, passed_with_warnings_count: -1, failed_count: -1, last_name: 1, first_name: 1}}
    json = Student.collection.aggregate(pipeline_with_sort_criterion).as_json
    content_type 'application/csv'
    csv_with_headers Classroom::Reports::Formats.format_report('csv', json)
  end

  get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
    Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
  end
end
