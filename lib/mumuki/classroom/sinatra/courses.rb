class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def allowed_courses
      {courses: Course.allowed_for(current_user).as_json}
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

    def ensure_organization_existence!
      Organization.locate! organization
    end

    # TODO: Use JSON Builder
    def with_last_invitation(course)
      course.as_json(except: [:created_at, :updated_at, :id], methods: [:current_invitation]).tap do |it|
        it['invitation'] = it['current_invitation']
        it.except! 'current_invitation'
      end
    end

    def guide_progress_report(matcher, projection)
      projection = csv_projection_for projection
      aggregation = Mumuki::Classroom::GuideProgress.where(matcher).project(projection)
      pipeline_with_sort_criterion = aggregation.pipeline << {'$sort': {email: 1, passed_count: -1, passed_with_warnings_count: -1, failed_count: -1, last_name: 1, first_name: 1}}
      json = Mumuki::Classroom::GuideProgress.collection.aggregate(pipeline_with_sort_criterion).as_json
      content_type 'application/csv'
      csv_with_headers(Mumuki::Classroom::Reports::Formats.format_report('csv', json), projection)
    end

    def guide_progress_report_projection
      {
          '_id': 0,
          'last_name': '$student.last_name',
          'first_name': '$student.first_name',
          'email': '$student.email',
          'last_submission': '$last_assignment.submission.created_at',
          'detached': {'$eq': ['$detached', true]},
          'guide_slug': '$guide.slug',
          'passed_count': '$stats.passed',
          'passed_with_warnings_count': '$stats.passed_with_warnings',
          'failed_count': '$stats.failed'
      }
    end
  end

  Mumukit::Platform.map_organization_routes!(self) do
    get '/courses' do
      allowed_courses
    end

    get '/api/courses' do
      allowed_courses
    end

    post '/courses' do
      authorize! :janitor
      ensure_organization_existence!
      ensure_normalized_slug! json_body[:slug]
      Course.create! with_current_organization(json_body)
      {status: :created}
    end

    get '/courses/:course' do
      authorize! :teacher
      {course: with_last_invitation(Course.locate!(course_slug))}
    end

    post '/courses/:course/invitation' do
      authorize! :janitor
      course = Course.locate! course_slug
      {invitation: course.invite!(json_body[:expiration_date])}
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
      authorize! :admin
      {exercise_student_progress: Mumuki::Classroom::Assignment.where(with_organization_and_course).as_json}
    end

    get '/courses/:course/report' do
      authorize! :teacher
      group_report with_organization_and_course, group_report_projection
    end

    get '/courses/:course/guide_progress_report' do
      authorize! :janitor
      guide_progress_report with_organization_and_course, guide_progress_report_projection
    end

    get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
      Mumuki::Classroom::Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
    end
  end
end
