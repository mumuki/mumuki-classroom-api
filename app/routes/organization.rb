get '/organization' do
  Mumukit::Bridge::Atheneum.organization_json.tap { |org| set_locale! org['organization'] }
end
