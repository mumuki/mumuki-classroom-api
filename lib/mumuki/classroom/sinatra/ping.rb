class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    get '/ping' do
      {message: 'pong!', organization: tenant}
    end
  end
end
