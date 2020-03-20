helpers do
  def normalize_student!
    json_body[:email] = json_body[:email]&.downcase
    json_body[:last_name] = json_body[:last_name]&.downcase&.titleize
    json_body[:first_name] = json_body[:first_name]&.downcase&.titleize
  end

  def list_students(matcher)
    authorize! :teacher
    count, students = Sorting.aggregate(Student, with_detached_and_search(matcher, Student), paginated_params, query_params)
    { page: page + 1, total: count, students: students }
  end
end

Mumukit::Platform.map_organization_routes!(self) do

  get '/courses/:course/students' do
    list_students with_organization_and_course
  end

  get '/api/courses/:course/students' do
    authorize! :teacher
    query_params = params.slice('uid', 'personal_id')
    {students: Student.where(with_organization_and_course.merge query_params)}
  end

  get '/students' do
    list_students with_organization
  end

  get '/students/report' do
    authorize! :janitor
    group_report with_organization, group_report_projection.merge(course: '$course')
  end

  get '/api/courses/:course/students/:uid' do
    authorize! :teacher
    {guide_students_progress: GuideProgress.where(with_organization_and_course 'student.uid': uid).sort(created_at: :asc).as_json}
  end

  post '/courses/:course/students/:uid' do
    authorize! :janitor
    Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
    {status: :created}
  end

  post '/courses/:course/students/:uid/detach' do
    authorize! :janitor
    Student.find_by!(with_organization_and_course uid: uid).detach!
    update_and_notify_student_metadata(uid, 'remove', course_slug)
    {status: :updated}
  end

  post '/courses/:course/students/:uid/attach' do
    authorize! :janitor
    Student.find_by!(with_organization_and_course uid: uid).attach!
    update_and_notify_student_metadata(uid, 'add', course_slug)
    {status: :updated}
  end

  post '/courses/:course/students/:uid/transfer' do
    authorize! :admin

    destination = Mumukit::Auth::Slug.join organization, json_body[:destination]

    Student.find_by!(with_organization_and_course uid: uid).transfer_to! organization, destination.to_s

    update_and_notify_student_metadata(uid, 'update', course_slug, destination.to_s)
    {status: :updated}
  end

  get '/courses/:course/student/:uid' do
    authorize! :teacher

    Student.find_by!(with_organization_and_course uid: uid).as_json
  end

  post '/courses/:course/students' do
    authorize! :janitor
    ensure_course_existence!
    ensure_student_not_exists!

    normalize_student!

    student_json = json_body.merge(uid: json_body[:email])
    uid = student_json[:uid]

    Student.create!(with_organization_and_course student_json)

    user = User.where(uid: uid).first_or_initialize(student_json.except(:personal_id))
    user.add_permission!(:student, course_slug)
    user.save!

    Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
    notify_new_user!(user)

    {status: :created}
  end

  put '/courses/:course/students/:uid' do
    authorize! :janitor
    ensure_course_existence!

    normalize_student!

    student = Student.find_by!(with_organization_and_course uid: uid)
    student.update_attributes!(first_name: json_body[:first_name], last_name: json_body[:last_name], personal_id: json_body[:personal_id])

    user = User.find_by(uid: uid)
    user.update_attributes! first_name: json_body[:first_name], last_name: json_body[:last_name]

    user.notify!

    {status: :updated}
  end
end
