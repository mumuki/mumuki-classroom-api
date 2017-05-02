Mumukit::Platform.map_organization_routes!(self) do
  get '/permissions' do
    authorize! :teacher

    {permissions: permissions}
  end
end
