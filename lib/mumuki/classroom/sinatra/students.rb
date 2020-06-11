class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def students_query
      with_detached_and_search with_organization_and_course, Mumuki::Classroom::Student
    end

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
      update_and_notify_student_metadata(uid, 'remove', course_slug)
      {status: :updated}
    end

    # Attaches a student to a course
    post '/courses/:course/students/:uid/attach' do
      authorize! :janitor
      Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid).attach!
      update_and_notify_student_metadata(uid, 'add', course_slug)
      {status: :updated}
    end

    # Transfers a student to another course
    post '/courses/:course/students/:uid/transfer' do
      authorize! :janitor

      slug = json_body[:slug].to_mumukit_slug

      authorize_for! :janitor, slug

      Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid).transfer_to! slug.organization, slug.to_s

      update_and_notify_student_metadata(uid, 'update', course_slug, json_body[:slug])
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
      ensure_student_not_exists!

      json = {student: to_student_basic_hash(json_body)}
      uid = json[:student][:uid]
      student = Mumuki::Classroom::Student.create!(with_organization_and_course json[:student])

      user = User.where(uid: uid).first_or_create!(student.as_user)
      user.add_permission! :student, course_slug
      user.save!

      Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant

      {status: :created}
    end

    # Updates student information
    put '/courses/:course/students/:uid' do
      authorize! :janitor
      ensure_course_existence!

      normalize_student!

      student = Mumuki::Classroom::Student.find_by!(with_organization_and_course uid: uid)
      student.update_attributes!(first_name: json_body[:first_name], last_name: json_body[:last_name], personal_id: json_body[:personal_id])

      user = User.find_by(uid: uid)
      user.update_attributes! first_name: json_body[:first_name], last_name: json_body[:last_name]

      user.notify!

      {status: :updated}
    end
  end
end
