class Mumuki::Classroom::App < Sinatra::Application
  Mumukit::Platform.map_organization_routes!(self) do
    get '/courses/:course/teachers' do
      authorize! :headmaster
      {teachers: Mumuki::Classroom::Teacher.where(with_organization_and_course).as_json}
    end

    post '/courses/:course/teachers' do
      authorize! :headmaster
      json = with_organization_and_course teacher: json_body.merge(uid: json_body[:email])
      Mumuki::Classroom::Teacher.create! with_organization_and_course(to_teacher_basic_hash json[:teacher])
      upsert_users! :teacher, [json[:teacher]]
    end
  end
end
