helpers do
  def follower_query
    with_organization_and_course email: params[:email]
  end

  def follower_query_from_body
    with_organization_and_course email: json_body[:email]
  end
end

post '/courses/:course/followers' do
  authorize! :teacher
  Follower.find_or_create_by!(follower_query_from_body).add!(json_body[:uid])
  {status: :created}
end

post '/courses/:course/followers/:email' do
  authorize! :teacher
  Follower.find_or_create_by!(follower_query).add!(json_body[:uid])
  {status: :created}
end

get '/courses/:course/followers/:email' do
  by_permissions :followers do |grants|
    {followers: Follower.where(follower_query.merge(course: {'$regex': grants})).as_json}
  end
end

delete '/courses/:course/followers/:email/:uid' do
  authorize! :teacher
  Follower.find_by!(follower_query).remove!(params[:uid])
  {status: :created}
end
