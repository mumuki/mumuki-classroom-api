get '/courses' do
  by_permissions :courses do |grants|
    Classroom::Collection::Courses.allowed(grants).as_json
  end
end

get '/api/courses' do
  by_permissions :courses, :auth do |grants|
    Classroom::Collection::Courses.allowed(grants).as_json
  end
end

post '/courses' do
  json = json_body.with_indifferent_access
  course = json.merge(uid: json[:slug])
  permissions.protect! :janitor, json[:slug]

  Classroom::Collection::Courses.ensure_new! json[:uid]
  Classroom::Collection::Courses.upsert! course

  Mumukit::Nuntius::EventPublisher.publish('CourseChanged', {course: course})

  {status: :created}
end
