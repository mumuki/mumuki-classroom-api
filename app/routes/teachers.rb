get '/courses/:course/teachers' do
  authorize! :teacher
  Classroom::Collection::Teachers.for(course).all.as_json
end

post '/courses/:course/teachers' do
  authorize! :teacher

  ensure_course_existence!
  Classroom::Collection::Teachers.for(course).ensure_new! json_body['email']
  json = {teacher: json_body.merge(uid: json_body['email']), course: {slug: course_slug}}
  Classroom::Collection::Teachers.for(course).insert!(json[:teacher].wrap_json)

  perm = Classroom::Collection::Users.upsert_permissions! json[:teacher][:uid], {teacher: course_slug}
  Mumukit::Nuntius::EventPublisher.publish 'UserChanged', user: json[:teacher].merge(permissions: perm)

  {status: :created}
end
