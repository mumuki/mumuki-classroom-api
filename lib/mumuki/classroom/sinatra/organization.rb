Mumukit::Platform.map_organization_routes!(self) do
  get '/organization' do
    organization_json
  end
end
