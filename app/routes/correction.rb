helpers do
  def correction_assignment_query
    with_organization_and_course 'exercise.eid': params[:exercise_id].to_i, 'student.uid': params[:uid], 'guide.slug': repo_slug
  end
end

Mumukit::Platform.map_organization_routes!(self) do
  post '/courses/:course/guides/:organization/:repository/:exercise_id/student/:uid/correction' do
    Assignment
      .find_by!(correction_assignment_query)
      .correct! json_body[:sid], json_body[:content], json_body[:status]
    {status: :updated}
  end
end

