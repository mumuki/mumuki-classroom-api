get '/courses/:course/teachers' do
  authorize! :teacher
  {teachers: Teacher.where(with_organization_and_course).as_json}
end
