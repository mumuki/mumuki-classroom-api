class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def manual_evaluation_assignment_query
      with_organization_and_course 'exercise.eid': params[:exercise_id].to_i, 'student.uid': params[:uid], 'guide.slug': repo_slug
    end
  end

  Mumukit::Platform.map_organization_routes!(self) do
    post '/courses/:course/guides/:organization/:repository/:exercise_id/student/:uid/manual_evaluation' do
      assignment = Mumuki::Classroom::Assignment.find_by!(manual_evaluation_assignment_query)
      assignment.evaluate_manually!(json_body[:sid], json_body[:comment], json_body[:status])
      assignment.notify_manual_evaluation!(json_body[:sid])
    end
  end
end

