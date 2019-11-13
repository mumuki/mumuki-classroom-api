helpers do
  def uids
    json_body[:uids].to_a.take(100)
  end

  def students
    json_body[:students].to_a.take(100)
  end

  def normalize_students! #TODO: refactor
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

  namespace '/api/courses/:course/massive' do

    get '/students' do
      authorize! :janitor
      per_page = 100
      progress = GuideProgress
                   .where(with_organization_and_course)
                   .sort('organization': :asc, 'course': :asc, 'student.uid': :asc)
                   .limit(per_page)
                   .skip(page * per_page)

      count = progress.count
      guide_progress = progress.select(&:student)
                         .map { |it| {student: it.student.uid, guide: it.guide.slug, progress: it} }

      {
        page: page + 1,
        total_pages: (count / per_page.to_f).ceil,
        total_results: count,
        total_page_results: [per_page, guide_progress.size].min,
        guide_students_progress: guide_progress
      }
    end

    post '/students' do
      authorize! :janitor
      ensure_course_existence!
      ensure_students_not_exist!
      create_students!
      upsert_users!
      {status: :created, processed: students, processed_count: students.size}
    end

    post '/students/detach' do
      authorize! :janitor
      Student.detach_all_by! uids, with_organization_and_course
      User.in(uid: uids).each { |uid| update_and_notify_user_metadata(uid, 'add', course_slug) }
      {status: :updated, processed_count: uids.size, processed: uids}
    end

    post '/exams/:exam_id/students' do
      authorize! :janitor
      exam = Exam.find_by!(exam_query)
      exam.add_students! uids
      exam.notify!
      {status: :updated}.merge(eid: exam_id, processed_count: uids.size, processed: uids)
    end
  end

end
