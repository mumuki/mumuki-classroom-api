helpers do
  def message
    message = json_body[:message]
    message[:sender] = current_user.uid
    message
  end

  def suggestion_for(assignment, submission)
    message.merge(guide_slug: assignment.guide['slug'], exercise: assignment.exercise, submissions: [submission])
  end

  def render_threads(course)
    authorize! :student
    query = with_organization exercise_student_progress_query.merge(course: course, 'exercise.eid': exercise_id)
    threads = Assignment.find_by!(query).threads(params[:language])
    erb :'threads.html', locals: {threads: threads, user: current_user}
  end

  def assignment_query
    with_organization_and_course 'exercise.eid': json_body[:exercise_id], 'student.uid': json_body[:uid], 'guide.slug': json_body[:guide_slug]
  end

  def submission_id
    json_body[:submission_id]
  end
end

Mumukit::Platform.map_organization_routes!(self) do
  post '/courses/:course/messages' do
    authorize! :teacher
    assignment = Assignment.find_by!(assignment_query)
    submission = assignment.add_message_to_submission!(message, submission_id)
    Suggestion.create suggestion_for(assignment, submission)

    {status: :created, message: Message.new(message)}
  end

  get '/courses/:course/guides/:organization/:repository/:exercise_id/student/:uid/messages' do
    render_threads(course_slug)
  end

  get '/api/guides/:organization/:repository/:exercise_id/student/:uid/messages' do
    render_threads Student.last_updated_student_by(with_organization uid: uid).course
  end
end

