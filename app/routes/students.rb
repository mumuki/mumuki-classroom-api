helpers do
  def students_query
    with_detached_and_search with_organization_and_course
  end
end

Mumukit::Platform.map_organization_routes!(self) do

  get '/courses/:course/students' do
    authorize! :teacher
    count, students = Sorting.aggregate(Student, students_query, paginated_params)
    {
      page: page + 1,
      total: count,
      students: students
    }
  end

  get '/api/courses/:course/students' do
    authorize! :teacher
    query_params = params.slice('uid', 'personal_id')
    {students: Student.where(with_organization_and_course.merge query_params)}
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
    update_and_notify_student_metadata(uid, 'remove')
    {status: :updated}
  end

  post '/courses/:course/students/:uid/attach' do
    authorize! :janitor
    Student.find_by!(with_organization_and_course uid: uid).attach!
    update_and_notify_student_metadata(uid, 'add')
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

    json_body[:email] = json_body[:email].downcase
    json_body[:first_name] = json_body[:first_name].downcase.titleize
    json_body[:last_name] = json_body[:last_name].downcase.titleize

    json = {student: json_body.merge(uid: json_body[:email]), course: {slug: course_slug}}
    uid = json[:student][:uid]

    Student.create!(with_organization_and_course json[:student])

    perm = User.where(uid: uid).first_or_create!(json[:student].except(:first_name, :last_name, :personal_id)).permissions
    perm.add_permission!(:student, course_slug)
    User.upsert_permissions! uid, perm

    Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
    Mumukit::Nuntius.notify_event! 'UserChanged', user: json[:student].except(:personal_id).merge(permissions: perm)

    {status: :created}
  end

  put '/courses/:course/students/:uid' do
    authorize! :janitor
    ensure_course_existence!

    student = Student.find_by!(with_organization_and_course uid: uid)
    student.update_attributes! first_name: json_body[:first_name].downcase.titleize, last_name: json_body[:last_name].downcase.titleize, personal_id: json_body[:personal_id]

    {status: :updated}
  end
end
