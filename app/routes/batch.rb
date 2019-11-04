helpers do
  def uids
    params[:uids] || []
  end

  def students
    json_body[:students] || []
  end

  def normalize_students!
    students.each do |it|
      it[:email] = it[:email]&.downcase
      it[:last_name] = it[:last_name]&.downcase&.titleize
      it[:first_name] = it[:first_name]&.downcase&.titleize
      it[:uid] = it[:email]
    end
  end

  def create_students!
    normalize_students!
    Student.create(students.map { |student| with_organization_and_course student })
  end

  def upsert_users!
    students.each do |student|
      uid = student[:uid]
      perm = User.where(uid: uid).first_or_create!(student.except(:first_name, :last_name, :personal_id)).permissions
      perm.add_permission!(:student, course_slug)
      User.upsert_permissions! uid, perm

      Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
      Mumukit::Nuntius.notify_event! 'UserChanged', user: student.except(:personal_id).merge(permissions: perm)
    end
  end
end

Mumukit::Platform.map_organization_routes!(self) do

  get '/api/courses/:course/massive/students' do
    authorize! :janitor
    per_page = 100
    progress = GuideProgress
                 .where(with_organization_and_course)
                 .sort('student.uid': :asc, 'guide.slug': :asc)
                 .limit(page * per_page)
                 .skip(per_page)
    {
      guide_students_progress: progress.map { |it| {student: it.student.uid, progress: it} },
      total: progress.count,
      page: page + 1
    }
  end

  post '/api/courses/:course/massive/students' do
    authorize! :janitor
    ensure_course_existence!
    create_students!
    upsert_users!
    {status: :created}
  end

  post '/api/courses/:course/massive/students/detach' do
    authorize! :janitor
    Student.detach_all_by! uids, with_organization_and_course
    uids.each { |uid| update_and_notify_student_metadata(uid, 'add', course_slug) }
    {status: :updated}
  end

  post '/api/courses/:course/massive/exams/:exam_id/students' do
    authorize! :janitor
    exam = Exam.find_by!(exam_query)
    exam.add_students! uids
    exam.notify!
    {status: :updated}.merge(eid: exam_id)
  end

end
