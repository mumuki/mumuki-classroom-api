post '/courses/:course/comments' do
  authorize! :teacher
  Classroom::Collection::ExerciseStudentProgress.for(organization, course).comment!(json_body)
  Mumukit::Nuntius::Publisher.publish_comments tenantized_json_body.except(:social_id, :uid)
  {status: :created}
end
