Mumukit::Platform.map_organization_routes!(self) do

  get '/courses/:course/students' do
    authorize! :teacher
    page = (params[:page] || 1).to_i - 1
    per_page = (params[:per_page] || 30).to_i
    sort_by = params[:sort_by] || :name
    with_detached = params[:with_detached].boolean_value
    query = params[:q] || ''
    order_by = params[:order_by] || :asc
    sorting_criteria = Sorting::Student.from(sort_by, order_by)
    student_where = Student.where(with_organization_and_course).with_detached(with_detached).search(query)
    {
      page: page + 1,
      total: student_where.count,
      students: student_where.order_by(sorting_criteria).limit(per_page).skip(page * per_page)
    }
  end

  get '/api/courses/:course/students' do
    authorize! :teacher
    {students: Student.where(with_organization_and_course)}
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

    json = {student: json_body.merge(uid: json_body[:email]), course: {slug: course_slug}}
    uid = json[:student][:uid]

    Student.create!(with_organization_and_course json[:student])

    perm = User.where(uid: uid).first_or_create!(json[:student].except(:first_name, :last_name)).permissions
    perm.add_permission!(:student, course_slug)
    User.upsert_permissions! uid, perm

    Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
    Mumukit::Nuntius.notify_event! 'UserChanged', user: json[:student].merge(permissions: perm)

    {status: :created}
  end
end
