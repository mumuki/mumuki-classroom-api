helpers do
  def message
    message = json_body[:message]
    message[:sender] = current_user.uid
    message
  end
end

Mumukit::Platform.map_organization_routes!(self) do
  post '/courses/:course/messages' do
    authorize! :teacher
    assignment = Assignment.find_by!(with_organization_and_course 'exercise.eid': json_body[:exercise_id], 'student.uid': json_body[:uid])
    assignment.add_message! message, json_body[:submission_id]
    assignment.notify_message! message, json_body[:submission_id]
    {status: :created, message: Message.new(message)}
  end

  get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id/messages' do
    authorize! :student
    threads = Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).threads(params[:language])
    erb :'threads.html', locals: {threads: threads, user: current_user}
  end

  get '/api/guides/:organization/:repository/:uid/:exercise_id/messages' do
    authorize! :student
    course_slug = Student.last_updated_student_by(with_organization uid: uid).course
    threads = Assignment.find_by!(with_organization exercise_student_progress_query.merge(course: course_slug, 'exercise.eid': exercise_id)).threads(params[:language])
    erb :'threads.html', locals: {threads: threads, user: current_user}
  end
end

