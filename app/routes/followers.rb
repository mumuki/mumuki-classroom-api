post '/courses/:course/followers' do
  protect!
  json_body['course'] = course_slug
  json_body['social_ids'].each do |social_id|
    body = {social_id: social_id, course: json_body['course'], email: json_body['email']}.stringify_keys
    Classroom::Collection::Followers.for(course).add_follower body
  end
  {status: :created}
end

get '/courses/:course/followers/:email' do
  by_permissions :followers do | grants |
    Classroom::Collection::Followers.for(course).where(email: params[:email], course: { '$regex' => grants }).as_json
  end
end

post '/courses/:course/followers/:email/unfollow' do
  protect!
  json_body['social_ids'].each do |social_id|
    Classroom::Collection::Followers.for(course).remove_follower 'course' => course_slug, 'email' => params[:email], 'social_id' => social_id
  end
  {status: :created}
end
