post '/courses/:course/comments' do
  protect! :teacher
  Classroom::Collection::ExerciseStudentProgress.for(course).comment!(json_body)
  Mumukit::Nuntius::Publisher.publish_comments tenantized_json_body.except(:social_id)
  {status: :created}
end
