helpers do
  def allowed_courses(permissions)
    {courses: Course.allowed(organization, permissions).as_json}
  end

  def guide_progress_query
    with_detached_and_search with_organization_and_course('guide.slug': repo_slug), GuideProgress
  end

  def student_query
    with_organization_and_course('guide.slug': repo_slug)
  end

  def student_assignment_query(student)
    student_info = student.slice('first_name', 'last_name', 'email').transform_keys { |it| "student.#{it}" }
    student_query.merge(student_info)
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
      items_to_review = Assignment.items_to_review(student_assignment_query(student), exercises)
      student['items_to_review'] = items_to_review.join ', '
    end
  end

  def normalized_exercises
    json_body[:exercises].map do |it|
      {language: json_body[:language]}.merge(it.symbolize_keys)
    end
  end

  def validate_organization_exists!
    raise Classroom::OrganizationNotExistsError unless Organization.find_by name: organization
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
    validate_organization_exists!
    course = Course.create! with_organization(json_body)
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
    count, guide_progress = Sorting.aggregate(GuideProgress, guide_progress_query, paginated_params, query_params)
    {
      total: count,
      page: page + 1,
      guide_students_progress: guide_progress
    }
  end

  post '/courses/:course/guides/:organization/:repository/report' do
    authorize! :teacher
    json = Reporting.aggregate(GuideProgress, guide_progress_query, paginated_params, query_params, guide_report_projection).as_json
    add_failed_tags json, normalized_exercises
    content_type 'application/csv'
    csv_with_headers(Classroom::Reports::Formats.format_report('csv', json), guide_report_projection)
  end

  get '/courses/:course/guides/:organization/:repository/:uid' do
    authorize! :teacher
    {exercise_student_progress: Assignment.with_full_messages(with_organization_and_course(exercise_student_progress_query), current_user)}
  end

  get '/courses/:course/progress' do
    authorize! :admin
    {exercise_student_progress: Assignment.where(with_organization_and_course).as_json}
  end

  get '/courses/:course/report' do
    authorize! :teacher
    group_report with_organization_and_course, group_report_projection
  end

  get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
    Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
  end
end
