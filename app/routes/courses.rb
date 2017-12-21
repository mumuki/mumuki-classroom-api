helpers do
  def allowed_courses(permissions)
    {courses: Course.allowed(organization, permissions).as_json}
  end

  def projection
    {
      '_id': 0,
      'last_name': '$last_name',
      'first_name': '$first_name',
      'email': '$email',
      'last_submission_date': '$last_assignment.submission.created_at',
      'passed_count': '$stats.passed',
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
    sorting_criteria = Sorting::GuideProgress.from(sort_by, order_by)
    guide_progress_where = GuideProgress
                             .where(with_organization_and_course 'guide.slug': repo_slug)
                             .with_detached(with_detached)
                             .search(query)
    {
      page: page + 1,
      total: guide_progress_where.count,
      guide_students_progress: guide_progress_where.order_by(sorting_criteria).limit(per_page).skip(page * per_page)
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
    json = Student.collection.aggregate(aggregation.pipeline).as_json
    content_type 'application/csv'
    csv_with_headers Classroom::Reports::Formats.format_report('csv', json)
  end

  get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
    Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
  end
end
