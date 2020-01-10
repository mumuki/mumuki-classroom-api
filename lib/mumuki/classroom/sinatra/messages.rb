class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def message
      message = json_body[:message]
      message[:sender] = current_user.uid
      message
    end

    def render_threads(course)
      authorize! :student
      query = with_organization exercise_student_progress_query.merge(course: course, 'exercise.eid': exercise_id)
      threads = Mumuki::Classroom::Assignment.find_by!(query).threads(params[:language])
      erb :'threads.html', locals: {threads: threads, user: current_user}
    end

    def assignment_query
      with_organization_and_course 'exercise.eid': json_body[:exercise_id], 'student.uid': json_body[:uid], 'guide.slug': json_body[:guide_slug]
    end

    def find_or_create_suggestion(assignment)
      suggestion_id ? Mumuki::Classroom::Suggestion.find(suggestion_id) : Mumuki::Classroom::Suggestion.create_from(message, assignment)
    end

    def submission_id
      json_body[:submission_id]
    end

    def suggestion_id
      json_body[:suggestion_id]
    end
  end

  Mumukit::Platform.map_organization_routes!(self) do
    post '/courses/:course/messages' do
      authorize! :teacher
      assignment = Mumuki::Classroom::Assignment.find_by!(assignment_query)
      submission = assignment.add_message_to_submission!(message, submission_id)
      find_or_create_suggestion(assignment).add_submission!(submission)

      {status: :created, message: Mumuki::Classroom::Message.new(message)}
    end

    get '/courses/:course/guides/:organization/:repository/:exercise_id/student/:uid/messages' do
      render_threads(course_slug)
    end

    get '/api/guides/:organization/:repository/:exercise_id/student/:uid/messages' do
      render_threads Mumuki::Classroom::Student.last_updated_student_by(with_organization uid: uid).course
    end
  end
end

