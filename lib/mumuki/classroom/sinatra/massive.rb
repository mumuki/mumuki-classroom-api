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
      @students ||= json_body[:students].map { |it| to_student_basic_hash it }
    end

    def teachers
      @teachers ||= json_body[:teachers].map { |it| to_teacher_basic_hash it }
    end

    def massive_students
      @massive_students ||= with_massive_batch_limit students
    end

    def massive_teachers
      @massive_teachers ||= with_massive_batch_limit teachers
    end

    def user_from_member_json(member_json)
      User.whitelist_attributes member_json
    end

    def to_member_basic_hash(member)
      {
        uid: (member[:uid] || member[:email])&.downcase,
        email: member[:email]&.downcase,
        last_name: member[:last_name]&.downcase&.titleize,
        first_name: member[:first_name]&.downcase&.titleize,
        personal_id: member[:personal_id]
      }
    end

    def to_student_basic_hash(student)
      to_member_basic_hash(student).merge personal_id: student[:personal_id]
    end

    def to_teacher_basic_hash(teacher)
      to_member_basic_hash teacher
    end

    #FIXME: This method now doesn't perform a bulk update as PG doesn't support it
    def upsert_users!(role, members)
      members.each do |it|
        user = User.find_or_initialize_by(uid: it[:uid])
        user.assign_attributes user_from_member_json(it)
        user.add_permission! role, course_slug
        user.save!
        yield user if block_given?
      end
    end

    def massive_response(processed, unprocessed, errored, errored_msg, hash = {})
      add_massive_response_field(:errored_members, errored, errored_msg, hash)
      add_massive_response_field(:unprocessed, unprocessed, unprocessed_msg, hash)
      hash.merge(processed_count: processed.size, processed: processed)
    end

    def unprocessed_msg
      "This endpoint process only first #{MASSIVE_BATCH_LIMIT} elements"
    end

    def add_massive_response_field(field, list, message, hash)
      unless list.empty?
        hash["#{field}_reason".to_sym] = message
        hash["#{field}_count".to_sym] = list.size
        hash[field.to_sym] = list
      end
    end

    def create_members!(role, &block)
      all_members = send role.to_s.pluralize
      massive_members = send "massive_#{role.to_s.pluralize}"
      col = "Mumuki::Classroom::#{role.to_s.titleize}".constantize
      existing_members = col.where(with_organization_and_course)
                           .in(uid: massive_members.map { |it| it[:uid] })
                           .map { |it| send "to_#{role}_basic_hash", it }
      existing_members_uids = existing_members.map { |it| it[:uid] }
      processed_members = massive_members.reject { |it| existing_members_uids.include? it[:uid] }
      col.collection.insert_many(processed_members.map { |member| with_organization_and_course member })
      upsert_users! role, processed_members, &block
      massive_response(processed_members, (all_members - massive_members), existing_members,
                       "#{role.to_s.pluralize.titleize} already belong to current course", status: :created)
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
        create_members! :student do |user|
          Mumukit::Nuntius.notify! 'resubmissions', uid: user.uid, tenant: tenant
        end
      end

      post '/teachers' do
        authorize! :janitor
        create_members! :teacher
      end

      post '/students/detach' do
        authorize! :janitor
        Mumuki::Classroom::Student.detach_all_by! massive_uids, with_organization_and_course
        User.where(uid: massive_uids).each { |uid| update_and_notify_user_metadata(uid, 'remove', course_slug) }
        {status: :updated, processed_count: massive_uids.size, processed: massive_uids}
      end

      post '/students/attach' do
        authorize! :janitor
        Mumuki::Classroom::Student.attach_all_by! massive_uids, with_organization_and_course
        User.where(uid: massive_uids).each { |uid| update_and_notify_user_metadata(uid, 'add', course_slug) }
        {status: :updated, processed_count: massive_uids.size, processed: massive_uids}
      end

      post '/exams/:exam_id/students' do
        authorize! :janitor
        processed = Mumuki::Classroom::Student.where(with_organization_and_course).in(uid: massive_uids).map(&:uid)
        Exam.upsert_students! eid: exam_id, added: processed
        massive_response processed, (uids - massive_uids), (massive_uids - processed),
                         'Students does not belong to current course', status: :updated, eid: exam_id
      end
    end
  end
end
