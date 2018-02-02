helpers do
  def students_query
    with_detached_and_search with_organization_and_course
  end

  def logger
    @logger ||= ::Logger.new(File.join 'logs', 'students.log')
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
    logger.info "POST /courses/#{course}/students"
    authorize! :janitor

    logger.info "- Ensuring #{course_slug} exists"
    ensure_course_existence!
    logger.info "- #{course_slug} exists!"

    logger.info "- Ensuring #{json_body[:email]} exists"
    ensure_student_not_exists!
    logger.info "- #{json_body[:email]} exists"

    json_body[:email] = json_body[:email].downcase
    json_body[:first_name] = json_body[:first_name].downcase.titleize
    json_body[:last_name] = json_body[:last_name].downcase.titleize

    json = {student: json_body.merge(uid: json_body[:email]), course: {slug: course_slug}}
    uid = json[:student][:uid]

    logger.info "- Creating #{uid}"
    Student.create!(with_organization_and_course json[:student])
    logger.info "- #{uid} created"

    logger.info "- Creating or updating #{uid} permissions"
    perm = User.where(uid: uid).first_or_create!(json[:student].except(:first_name, :last_name, :personal_id)).permissions
    logger.info "- Permissions for #{uid}:"
    logger.info "- - Current: #{perm.as_json}"
    perm.add_permission!(:student, course_slug)
    logger.info "- - New: #{perm.as_json}"

    User.upsert_permissions! uid, perm
    logger.info "- #{uid} Created or updated"

    Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
    logger.info "- Notify resubmissions for #{uid}"

    Mumukit::Nuntius.notify_event! 'UserChanged', user: json[:student].merge(permissions: perm)
    logger.info "- Notify 'UserChanged' for #{uid}"

    {status: :created}
  end
end
