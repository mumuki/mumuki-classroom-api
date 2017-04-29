helpers do
  def follower_query
    with_organization_and_course email: params[:email]
  end

  def follower_query_from_body
    with_organization_and_course email: json_body[:email]
  end
end

Mumukit::Platform.map_organization_routes!(self) do
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
    {followers: Follower
                  .where(follower_query)
                  .where(email: params[:email])
                  .select { |it| permissions.has_permission? :teacher, it.course }
                  .as_json
    }
  end

  delete '/courses/:course/followers/:email/:uid' do
    authorize! :teacher
    Follower.find_by!(follower_query).remove!(params[:uid])
    {status: :created}
  end
end
