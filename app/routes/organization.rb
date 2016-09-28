get '/organization' do
  Classroom::Atheneum.organization_json.tap { |org| set_locale! org['organization'] }
end
