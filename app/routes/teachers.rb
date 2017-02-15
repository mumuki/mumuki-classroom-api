get '/courses/:course/teachers' do
  authorize! :teacher
  Classroom::Collection::Teachers.for(course).all.as_json
end
