post '/courses/:course/followers' do
  protect! :teacher
  json_body['course'] = course_slug
  Classroom::Collection::Followers.for(course).add_follower json_body
  {status: :created}
end

get '/courses/:course/followers/:email' do
  by_permissions :followers do | grants |
    Classroom::Collection::Followers.for(course).where(email: params[:email], course: { '$regex' => grants }).as_json
  end
end

delete '/courses/:course/followers/:email/:uid' do
  protect! :teacher
  Classroom::Collection::Followers.for(course).remove_follower 'course' => course_slug, 'email' => params[:email], 'uid' => uid
  {status: :created}
end
