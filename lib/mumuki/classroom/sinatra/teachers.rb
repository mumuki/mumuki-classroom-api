class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    helpers do
      def list_teachers(matcher)
        authorize! :headmaster
        {teachers: Mumuki::Classroom::Teacher.where(matcher).as_json}
      end
    end

    get '/teachers' do
      list_teachers with_organization
    end

    get '/courses/:course/teachers' do
      list_teachers with_organization_and_course
    end

    post '/courses/:course/teachers' do
      authorize! :headmaster

      create_course_member! :teacher
    end
  end
end
