class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    get '/courses/:course/teachers' do
      authorize! :headmaster
      {teachers: Mumuki::Classroom::Teacher.where(with_organization_and_course).as_json}
    end

    post '/courses/:course/teachers' do
      authorize! :headmaster
      ensure_teacher_not_exists!
      teacher_json = Mumuki::Classroom::Teacher.normalized_attributes_from_json json_body

      teacher = Mumuki::Classroom::Teacher.create! with_organization_and_course(teacher_json)

      upsert_user! :teacher, teacher.as_user
    end
  end
end
