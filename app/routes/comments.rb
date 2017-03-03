post '/courses/:course/comments' do
  authorize! :teacher
  Assignment
    .find_by!(with_organization_and_course 'exercise.eid': json_body[:exercise_id], 'student.uid': json_body[:uid])
    .comment! json_body[:comment], json_body[:submission_id]
  {status: :created}
end
