class Mumuki::Classroom::App < Sinatra::Application
  MASSIVE_BATCH_LIMIT = 100

  helpers do
    def with_massive_batch_limit(elements)
      elements.to_a.take MASSIVE_BATCH_LIMIT
    end

    def uids
      json_body[:uids]
    end

    def massive_uids
      with_massive_batch_limit uids
    end

    def students
      with_massive_batch_limit json_body[:students]
    end

    def user_from_student_json(student_json)
      User.new student_json.except(:first_name, :last_name, :personal_id)
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
      Mumuki::Classroom::Student.collection.insert_many(students.map { |student| with_organization_and_course student })
    end

    #FIXME: This method now doesn't perform a bulk update as PG doesn't support it
    def upsert_users!
      students.each do |it|
        user = User.find_or_initialize_by(uid: it[:uid])
        if user.new_record?
          user.assign_attributes user_from_student_json(:it)
        end
        user.add_permission! :student, course_slug
        user.save!
        Mumukit::Nuntius.notify! 'resubmissions', uid: user.uid, tenant: tenant
      end
    end
  end

  Mumukit::Platform.map_organization_routes!(self) do

    get '/api/courses/:course/massive/students' do
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

    post '/api/courses/:course/massive/students' do
      authorize! :janitor
      ensure_course_existence!
      ensure_students_not_exist!
      create_students!
      upsert_users!
      {status: :created, processed: students, processed_count: students.size}
    end

    post '/api/courses/:course/massive/students/detach' do
      authorize! :janitor
      Mumuki::Classroom::Student.detach_all_by! massive_uids, with_organization_and_course
      User.where(uid: massive_uids).each { |uid| update_and_notify_user_metadata(uid, 'remove', course_slug) }
      {status: :updated, processed_count: massive_uids.size, processed: massive_uids}
    end

    post '/api/courses/:course/massive/students/attach' do
      authorize! :janitor
      Mumuki::Classroom::Student.attach_all_by! massive_uids, with_organization_and_course
      User.where(uid: massive_uids).each { |uid| update_and_notify_user_metadata(uid, 'add', course_slug) }
      {status: :updated, processed_count: massive_uids.size, processed: massive_uids}
    end

    post '/api/courses/:course/massive/exams/:exam_id/students' do
      authorize! :janitor
      in_uids = Mumuki::Classroom::Student.where(with_organization_and_course).in(uid: massive_uids).map(&:uid)
      out_uids = massive_uids - in_uids
      Exam.upsert_students! eid: exam_id, added: in_uids
      {
        status: :updated,

        errored_members_reason: 'Students does not belong to current course',
        errored_members_count: out_uids.size,
        errored_members: out_uids,

        processed_count: in_uids.size,
        processed: in_uids,

        unprocessed_reason: "This endpoint process only first #{MASSIVE_BATCH_LIMIT} elements",
        unprocessed_count: [0, (uids - massive_uids).size].max,
        unprocessed: (uids - massive_uids),

        eid: exam_id
      }
    end
  end
end
