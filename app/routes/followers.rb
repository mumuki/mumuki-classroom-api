post '/courses/:course/followers' do
  authorize! :teacher
  Classroom::Collection::Followers.for(organization, course).add_follower json_body
  {status: :created}
end

get '/courses/:course/followers/:email' do
  by_permissions :followers do |grants|
    Classroom::Collection::Followers.for(organization, course).where(email: params[:email], course: {'$regex': grants}).as_json
  end
end

delete '/courses/:course/followers/:email/:uid' do
  authorize! :teacher
  Classroom::Collection::Followers.for(organization, course).remove_follower email: params[:email], uid: uid
  {status: :created}
end
