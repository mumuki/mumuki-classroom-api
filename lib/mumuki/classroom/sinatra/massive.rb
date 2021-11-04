class Mumuki::Classroom::App < Sinatra::Application

  Mumukit::Platform.map_organization_routes!(self) do

    namespace '/api/courses/:course/massive' do

      before do
        next if request.options?
        authorize! :janitor
        ensure_organization_exists!
        ensure_course_exists!
      end

      get '/students' do
        per_page = MASSIVE_BATCH_LIMIT
        progress = guide_progress_at_page per_page
        count = progress.count
        guide_progress = progress.select(&:student).map { |it| as_guide_progress_response it }
        {
          page: page + 1,
          total_pages: (count / per_page.to_f).ceil,
          total_results: count,
          total_page_results: [per_page, guide_progress.size].min,
          guide_students_progress: guide_progress
        }
      end

      post '/students' do
        create_members! :student do |user|
          Mumukit::Nuntius.notify! 'resubmissions', uid: user.uid, tenant: tenant
        end
      end

      post '/teachers' do
        create_members! :teacher
      end

      post '/students/detach' do
        update_students! do |processed|
          update_students_permissions_at_course! :detach, :remove, processed
        end
      end

      post '/students/attach' do
        update_students! do |processed|
          update_students_permissions_at_course! :attach, :add, processed
        end
      end

      post '/exams/:exam_id/students' do
        update_students! do |processed|
          Exam.upsert_students! eid: exam_id, added: processed
        end
      end
    end
  end

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
      @students ||= json_body[:students].map do |it|
        Mumuki::Classroom::Student.normalized_attributes_from_json it
      end
    end

    def teachers
      @teachers ||= json_body[:teachers].map do |it|
        Mumuki::Classroom::Teacher.normalized_attributes_from_json it
      end
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

    def upsert_user!(role, member)
      user = User.find_or_initialize_by(uid: member[:uid])
      user.assign_attributes user_from_member_json(member)
      user.add_permission! role, course_slug
      user.verify_name! force: true
      yield user if block_given?
    end

    #FIXME: This method now doesn't perform a bulk update as PG doesn't support it
    def upsert_users!(role, members, &block)
      members.each { |it| upsert_user! role, it, &block }
    end

    def massive_response(processed, unprocessed, errored, errored_msg, hash = {})
      add_massive_response_field(:errored_members, errored, errored_msg, hash)
      add_massive_response_field(:unprocessed, unprocessed, unprocessed_msg, hash)
      hash.merge(processed_count: processed.size, processed: processed)
    end

    def unprocessed_msg
      "This endpoint process only first #{MASSIVE_BATCH_LIMIT} elements"
    end

    def students_does_not_belong_msg
      'Students does not belong to current course'
    end

    def add_massive_response_field(field, list, message, hash)
      unless list.empty?
        hash["#{field}_reason".to_sym] = message
        hash["#{field}_count".to_sym] = list.size
        hash[field.to_sym] = list
      end
    end

    def members_for(role)
      send role.to_s.pluralize
    end

    def massive_members_for(role)
      send "massive_#{role.to_s.pluralize}"
    end

    def unprocessed_members_for(role)
      members_for(role) - massive_members_for(role)
    end

    def create_members!(role, &block)
      members_collection = collection_for role

      existing_members, non_existent_members = partion_existing_members_in_course(
        members_collection,
        massive_members_for(role))

      valid_members, invalid_members = non_existent_members.partition do |member|
        members_collection.valid_attributes? member
      end

      errored_members = existing_members + invalid_members

      members_collection
        .collection
        .insert_many(valid_members.map { |member| with_organization_and_course member })
      upsert_users! role, valid_members, &block

      massive_response(valid_members, unprocessed_members_for(role), errored_members,
                       "#{role.to_s.pluralize.titleize} already belong to current course", status: :created)
    end

    def partion_existing_members_in_course(collection, massive_members)
      existing_members = existing_members_in_course(collection, massive_members)
      existing_members_uids = existing_members.map { |it| it[:uid] }
      [
        existing_members,
        massive_members.reject { |it| existing_members_uids.include? it[:uid] }.uniq { |it| it[:uid] }
      ]
    end

    def existing_members_in_course(collection, massive_members)
      collection.where(with_organization_and_course)
        .in(uid: massive_members.map { |it| it[:uid] })
        .map { |it| collection.normalized_attributes_from_json(it) }
    end

    def update_students!
      processed = students_from(massive_uids).map(&:uid)
      yield processed if block_given?
      massive_response processed, (uids - massive_uids), (massive_uids - processed),
                       students_does_not_belong_msg, status: :updated
    end

    def update_students_permissions_at_course!(method, action, students_uids)
      Mumuki::Classroom::Student.send "#{method}_all_by!", students_uids, with_organization_and_course
      User.where(uid: students_uids).each do |user|
        user.send "#{action}_permission!", :student, course_slug
        user.save!
      end
    end

    def students_from(uids)
      Mumuki::Classroom::Student.where(with_organization_and_course).in(uid: uids)
    end

    def ensure_course_exists!
      Course.locate!(course_slug)
    end

    def ensure_organization_exists!
      Organization.locate!(organization).tap &:switch!
    end

    def guide_progress_at_page(per_page)
      Mumuki::Classroom::GuideProgress
        .where(with_organization_and_course)
        .sort('organization': :asc, 'course': :asc, 'student.uid': :asc)
        .limit(per_page)
        .skip(page * per_page)
    end

    def as_guide_progress_response(guide_progress)
      {
        student: guide_progress.student.uid,
        guide: guide_progress.slug,
        progress: guide_progress.as_json.except(:student, :guide)
      }
    end
  end
end

