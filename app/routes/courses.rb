helpers do
  def allowed_courses(grants)
    {courses: Course.where(with_organization).allowed(grants).as_json}
  end
end

get '/courses' do
  by_permissions(:courses) { |grants| allowed_courses grants }
end

get '/api/courses' do
  by_permissions(:courses, :auth) { |grants| allowed_courses grants }
end

post '/courses' do
  permissions.protect! :janitor, json_body[:slug]
  course = Course.create! with_organization(json_body.merge uid: json_body[:slug])
  course.notify!
  {status: :created}
end
