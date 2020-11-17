class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def normalize_student!
      json_body[:email] = json_body[:email]&.downcase
      json_body[:last_name] = json_body[:last_name]&.downcase&.titleize
      json_body[:first_name] = json_body[:first_name]&.downcase&.titleize
    end

    def list_students(matcher)
      authorize! :teacher
      count, students = Sorting.aggregate(Mumuki::Classroom::Student, with_detached_and_search(matcher, Mumuki::Classroom::Student), paginated_params, query_params)
      {page: page + 1, total: count, students: students}
    end

  end

  Mumukit::Platform.map_organization_routes!(self) do

    get '/courses/:course/students' do
      list_students with_organization_and_course
    end

    get '/api/courses/:course/students' do
      authorize! :teacher
      query_params = params.slice('uid', 'personal_id')
      {students: Mumuki::Classroom::Student.where(with_organization_and_course.merge query_params)}
    end

    get '/students' do
      list_students with_organization
    end

    get '/students/report' do
      authorize! :janitor
      group_report with_organization, group_report_projection.merge(course: '$course')
    end

    # Retrieves the progress for a student in an specific course
    get '/api/courses/:course/students/:uid' do
      authorize! :teacher
      {guide_students_progress: Mumuki::Classroom::GuideProgress.where(with_organization_and_course 'student.uid': uid).sort(created_at: :asc).as_json}
    end

    # Tries to resubmit all failed_submissions of a student to a specific tenant
    post '/courses/:course/students/:uid' do
      authorize! :janitor
      Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
      {status: :created}
    end

    # Detaches a student of a course
    post '/courses/:course/students/:uid/detach' do
      authorize! :janitor
      Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid).detach!
      update_user_permissions!(uid, 'remove', course_slug)
      {status: :updated}
    end

    # Attaches a student to a course
    post '/courses/:course/students/:uid/attach' do
      authorize! :janitor
      Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid).attach!
      update_user_permissions!(uid, 'add', course_slug)
      {status: :updated}
    end

    # Transfers a student to another course
    post '/courses/:course/students/:uid/transfer' do
      authorize! :admin

      destination = Mumukit::Auth::Slug.join organization, json_body[:destination]

      Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid).transfer_to!  organization, destination.to_s

      update_user_permissions!(uid, 'update', course_slug, destination.to_s)
      {status: :updated}
    end

    # Retrieves info for a particular student
    get '/courses/:course/student/:uid' do
      authorize! :teacher

      Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid).as_json
    end

    # Creates student and tries to resubmit all failed submissions to that student
    post '/courses/:course/students' do
      authorize! :janitor
      ensure_course_existence!

      student_json = create_course_member! :student

      Mumukit::Nuntius.notify! 'resubmissions', uid: student_json[:uid], tenant: tenant

      {status: :created}
    end

    # Updates student information
    put '/courses/:course/students/:uid' do
      authorize! :janitor
      ensure_course_existence!

      student = Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid)
      student.update! Mumuki::Classroom::Student.normalized_attributes_from_json(json_body).except(:uid)

      upsert_user! :student, student.as_user

      {status: :updated}
    end
  end
end
