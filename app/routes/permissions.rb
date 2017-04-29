get '/permissions' do
  authorize! :teacher

  {permissions: permissions}
end
