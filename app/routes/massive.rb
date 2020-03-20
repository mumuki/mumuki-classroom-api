MASSIVE_BATCH_LIMIT = 100

helpers do
  def with_massive_batch_limit(elements)
    elements.to_a.take MASSIVE_BATCH_LIMIT
  end

  def uids
    with_massive_batch_limit json_body[:uids]
  end

  def students
    with_massive_batch_limit json_body[:students]
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
    Student.collection.insert_many(students.map { |student| with_organization_and_course student })
  end

  def upsert_users!
    new_students_uids = students.map { |it| it[:uid] }
    existing_users = User.in(uid: new_students_uids).to_a
    new_users = new_students_uids - existing_users.map { |it| it[:uid] }

    new_students = students.select { |it| new_users.include? it[:uid] }.map do |it|
      User.from_student_json(it).tap do |new_user|
        new_user.add_permission!(:student, course_slug)
      end
    end

    User.collection.insert_many(new_students.as_json)

    User.bulk_permissions_update existing_users, :student, course_slug

    (new_students + existing_users).each do |it|
      notify_user! it
      Mumukit::Nuntius.notify! 'resubmissions', uid: it.uid, tenant: tenant
    end
  end
end

Mumukit::Platform.map_organization_routes!(self) do

  namespace '/api/courses/:course/massive' do

    get '/students' do
      authorize! :janitor
      per_page = MASSIVE_BATCH_LIMIT
      progress = GuideProgress
                   .where(with_organization_and_course)
                   .sort('organization': :asc, 'course': :asc, 'student.uid': :asc)
                   .limit(per_page)
                   .skip(page * per_page)

      count = progress.count
      guide_progress = progress.select(&:student)
                         .map { |it| {student: it.student.uid, guide: it.guide.slug, progress: it.as_json.except(:student, :guide)} }

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
      User.in(uid: uids).each { |uid| update_and_notify_user_metadata(uid, 'remove', course_slug) }
      {status: :updated, processed_count: uids.size, processed: uids}
    end

    post '/students/attach' do
      authorize! :janitor
      Student.attach_all_by! uids, with_organization_and_course
      User.in(uid: uids).each { |uid| update_and_notify_user_metadata(uid, 'add', course_slug) }
      {status: :updated, processed_count: uids.size, processed: uids}
    end

    post '/exams/:exam_id/students' do
      authorize! :janitor
      exam = Exam.find_by!(exam_query)
      exam.add_students! uids
      notify_exam_students! exam, added: uids
      {status: :updated}.merge(eid: exam_id, processed_count: uids.size, processed: uids)
    end
  end
end
