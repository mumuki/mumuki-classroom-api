post '/courses/:course/comments' do
  authorize! :teacher
  puts "HOLA: #{Assignment.last.as_json}"
  Assignment
    .find_by!(with_organization_and_course 'exercise.id': json_body[:exercise_id], 'student.uid': json_body[:uid])
    .tap { |it| puts "Result #{it}" }
    .comment! json_body
  Mumukit::Nuntius::Publisher.publish_comments tenantized_json_body.except(:social_id, :uid)
  {status: :created}
end
