post '/courses/:course/comments' do
  authorize! :teacher
  puts Assignment.find_by!('exercise.id': json_body[:exercise_id])
  Assignment
    .find_by!(with_organization_and_course 'student.uid': json_body[:uid], 'exercise.id': json_body[:exercise_id])
    .comment! json_body[:comment], json_body[:submission_id]
  Mumukit::Nuntius::Publisher.publish_comments tenantized_json_body.except(:social_id, :uid)
  {status: :created}
end
