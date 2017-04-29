helpers do
  def allowed_courses(permissions)
    {courses: Course.allowed(organization, permissions).as_json}
  end
end

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
  {guide_students_progress: GuideProgress.where(with_organization_and_course 'guide.slug': repo_slug).as_json}
end

get '/courses/:course/guides/:organization/:repository/:uid' do
  authorize! :teacher
  {exercise_student_progress: Assignment.where(with_organization_and_course exercise_student_progress_query).as_json}
end

get '/courses/:course/progress' do
  authorize! :teacher
  {exercise_student_progress: Assignment.where(with_organization_and_course).as_json}
end

get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
  Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
end
