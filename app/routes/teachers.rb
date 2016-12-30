get '/courses/:course/teachers' do
  protect! :teacher
  Classroom::Collection::Teachers.for(course).all.as_json
end
