helpers do
  def follower_query
    with_organization_and_course email: current_user.uid
  end
end

Mumukit::Platform.map_organization_routes!(self) do
  post '/courses/:course/followers' do
    authorize! :teacher
    Mumuki::Classroom::Follower.find_or_create_by!(follower_query).add!(json_body[:uid])
    {status: :created}
  end

  get '/courses/:course/followers' do
    {followers: Mumuki::Classroom::Follower
                  .where(follower_query)
                  .select { |it| permissions.has_permission? :teacher, it.course }
                  .as_json
    }
  end

  delete '/courses/:course/followers/:uid' do
    authorize! :teacher
    Mumuki::Classroom::Follower.find_by!(follower_query).remove!(params[:uid])
    {status: :created}
  end
end
