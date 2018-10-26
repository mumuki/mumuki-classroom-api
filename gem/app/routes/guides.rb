Mumukit::Platform.map_organization_routes!(self) do
  get '/guides/:organization/:repository' do
    authorize! :teacher
    {guide: Guide.find_by!(with_organization slug: repo_slug)}
  end
end