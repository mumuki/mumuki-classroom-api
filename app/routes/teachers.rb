get '/courses/:course/teachers' do
  authorize! :teacher
  Classroom::Collection::Teachers.for(organization, course).all.as_json
end
