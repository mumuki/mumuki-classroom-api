class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    get '/courses/:course/teachers' do
      authorize! :headmaster
      {teachers: Mumuki::Classroom::Teacher.where(with_organization_and_course).as_json}
    end

    post '/courses/:course/teachers' do
      authorize! :headmaster

      create_course_member! :teacher
    end
  end
end
