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

  def teachers
    with_massive_batch_limit json_body[:teachers]
  end

  def normalize_course_members!(members)
    members.each do |it|
      normalize_course_member! it
    end
  end

  def create_course_members!(member_collection, members)
    normalize_course_members! members
    members_uids = members.map { |it| it[:uid] }
    existing_members_uids = member_collection.where(with_organization_and_course uid: {'$in': members_uids}).map(&:uid)
    existing_members = members.select { |s| existing_members_uids.include? s[:uid] }
    new_members = members.reject { |s| existing_members_uids.include? s[:uid] }
    member_collection.collection.insert_many(new_members.map { |member| with_organization_and_course member })
    [new_members, existing_members]
  end

  def upsert_users!(members, role)
    new_members_uids = members.map { |it| it[:uid] }
    existing_users = User.in(uid: new_members_uids).to_a
    new_users_uids = new_members_uids - existing_users.map { |it| it[:uid] }

    new_users = members.select { |it| new_users_uids.include? it[:uid] }.map do |it|
      User.from_course_member_json(it).tap do |new_user|
        new_user.add_permission!(role, course_slug)
      end
    end

    User.collection.insert_many(new_users.as_json)

    User.bulk_permissions_update existing_users, :student, course_slug

    (new_users + existing_users).each do |it|
      notify_user! it, members.find { |json| json[:uid] == it.uid }
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
      processed, unprocessed = create_course_members! Student, students
      upsert_users! students, :student
      {
        status: :created,
        processed: processed,
        processed_count: processed.size,
        existing_students: unprocessed,
        existing_students_count: unprocessed.size
      }
    end

    post '/teachers' do
      authorize! :janitor
      ensure_course_existence!
      processed, unprocessed = create_course_members! Teacher, teachers
      upsert_users! teachers, :teacher
      {
          status: :created,
          processed: processed,
          processed_count: processed.size,
          existing_students: unprocessed,
          existing_students_count: unprocessed.size
      }
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
