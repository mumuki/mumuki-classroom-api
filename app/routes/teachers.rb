get '/courses/:course/teachers' do
  protect!
  Classroom::Collection::Teachers.for(course).all.as_json
end

post '/courses/:course/teachers' do
  protect!

  Mumukit::Auth::User.from_email(json_body['email']).tap do |user|
    ensure_course_existence!
    Classroom::Collection::Teachers.for(course).ensure_new! user.social_id, json_body['email']
    Classroom::Collection::Teachers.for(course).insert!(json_body.merge(image_url: user.user['picture'], social_id: user.social_id).wrap_json)
    Classroom::Collection::Students.for(course).delete!(user.social_id)

    user.update_permissions('classroom', course_slug)
    user.update_permissions('atheneum', "#{tenant}/*")
  end

  {status: :created}
end
