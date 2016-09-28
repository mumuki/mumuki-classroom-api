get '/courses' do
  by_permissions :courses do | grants |
    Classroom::Collection::Courses.allowed(grants).as_json
  end
end

post '/courses' do
  permissions.protect! json_body['slug']

  Classroom::Collection::Courses.ensure_new! json_body['slug']
  Classroom::Collection::Courses.insert! json_body.wrap_json

  {status: :created}
end
