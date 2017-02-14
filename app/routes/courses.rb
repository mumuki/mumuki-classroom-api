helpers do
  def allowed_courses(grants)
    Classroom::Collection::Courses.for(organization).allowed(grants).as_json
  end
end

get '/courses' do
  by_permissions(:courses) { |grants| allowed_courses grants }
end

get '/api/courses' do
  by_permissions(:courses, :auth) { |grants| allowed_courses grants }
end

post '/courses' do
  json = json_body.with_indifferent_access
  course = json.merge(uid: json[:slug])
  permissions.protect! :janitor, json[:slug]

  Classroom::Collection::Courses.for(organization).ensure_new! json[:uid]
  Classroom::Collection::Courses.for(organization).upsert! course

  Mumukit::Nuntius::EventPublisher.publish('CourseChanged', {course: course})

  {status: :created}
end
