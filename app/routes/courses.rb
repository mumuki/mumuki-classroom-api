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
