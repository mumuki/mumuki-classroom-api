Mumukit::Platform.map_organization_routes!(self) do
  post '/courses/:course/messages' do
    authorize! :teacher
    Assignment
      .find_by!(with_organization_and_course 'exercise.eid': json_body[:exercise_id], 'student.uid': json_body[:uid])
      .add_message! json_body[:message], json_body[:submission_id]
    {status: :created}
  end
end
