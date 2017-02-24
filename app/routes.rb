require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/service/routes'

require_relative './session_store'
require_relative './omniauth'
require_relative '../lib/classroom'

configure do
  set :app_name, 'classroom'
end

Mumukit::Login.configure_login_routes! self

helpers do
  Mumukit::Login.configure_controller! self
  Mumukit::Login.configure_login_controller! self

  def authenticate!
    halt 401 unless current_user?
  end

  def json_body
    @json_body ||= JSON.parse(request.body.read).with_indifferent_access rescue nil
  end

  def with_organization(hash = {})
    {organization: organization}.merge hash
  end

  def with_organization_and_course(hash = {})
    with_organization.merge(course: course_slug).merge hash
  end

  def authorization_slug
    slug
  end

  def permissions
    current_user.permissions
  end

  def course
    params[:course]
  end

  def uid
    params[:uid]
  end

  def exercise_id
    params[:exercise_id].to_i
  end

  def exercise_student_progress_query
    {'guide.slug': repo_slug, 'student.uid': uid}
  end

  def by_permissions(key, &query)
    grants = permissions_to_regex
    if grants.to_s.blank?
      {}.tap { |it| it[key] = [] }
    else
      query.call(grants)
    end
  end

  def permissions_to_regex
    permissions.to_s.gsub(/[:]/, '|').gsub(/[*]/, '.*')
  end

  def tenant
    request.first_subdomain
  end

  def organization
    tenant
  end

  def route_slug_parts
    [tenant, course].compact
  end

  def course_slug
    @course_slug ||= Mumukit::Auth::Slug.join_s(tenant, course)
  end

  def repo_slug
    @repo_slug ||= Mumukit::Auth::Slug.join_s(params[:organization], params[:repository])
  end

  def tenantized_json_body
    json_body.merge(tenant: tenant)
  end

  def ensure_course_existence!
    Course.ensure_exist! with_organization(slug: course_slug)
  end

  def ensure_course_student_existence!(uid)
    Classroom::Collection::CourseStudents.for(organization).ensure_exist! uid, course_slug
  end

  def set_locale!(org)
    I18n.locale = org['locale']
  end

  def organization_json
    @organization_json ||= Organization.find_by(name: organization).as_json
  end

  def update_and_notify_student_metadata(uid, method)
    permissions = Classroom::Collection::Users.find_by_uid!(uid).permissions
    permissions.send("#{method}_permission!", 'student', course_slug)
    Student.find_by(with_organization_and_course uid: uid).try do |user|
      user_as_json = user.as_json(only: [:first_name, :last_name, :email])
      user_to_notify = user_as_json.merge(uid: uid, permissions: permissions)
      Mumukit::Nuntius::EventPublisher.publish('UserChanged', {user: user_to_notify})
    end
  end

  def notify_upsert_exam(exam_id)
    Mumukit::Nuntius::EventPublisher.publish('UpsertExam', tenantized_json_body.except(:social_ids).merge(exam_id))
  end

end

before do
  Classroom::Database.connect!
  set_locale! organization_json if organization_json
end

require_relative './routes/courses'
require_relative './routes/comments'
require_relative './routes/errors'
require_relative './routes/exams'
require_relative './routes/followers'
require_relative './routes/organization'
require_relative './routes/ping'
require_relative './routes/teachers'

get '/courses/:course/students' do
  authorize! :teacher
  {students: Student.where(with_organization_and_course)}
end

get '/api/courses/:course/students' do
  authorize! :teacher
  {students: Student.where(with_organization_and_course)}
end

get '/api/courses/:course/students/:uid' do
  authorize! :teacher
  Classroom::Collection::GuideStudentsProgress.for(organization, course).where('student.uid': uid).as_json
end

post '/courses/:course/students/:uid' do
  authorize! :janitor
  Mumukit::Nuntius::Publisher.publish_resubmissions(uid: uid, tenant: tenant)
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

get '/courses/:course/guides' do
  authorize! :teacher
  {guides: Guide.where(with_organization_and_course).as_json}
end

get '/api/courses/:course/guides' do
  authorize! :teacher
  {guides: Guide.where(with_organization_and_course).as_json}
end

get '/courses/:course/guides/:organization/:repository' do
  authorize! :teacher
  Classroom::Collection::GuideStudentsProgress.for(organization, course).where('guide.slug': repo_slug).as_json
end

get '/courses/:course/guides/:organization/:repository/:uid' do
  authorize! :teacher
  {exercise_student_progress: Assignment.where(with_organization_and_course exercise_student_progress_query).as_json}
end

get '/courses/:course/progress' do
  authorize! :teacher
  {exercise_student_progress: Assignment.where(with_organization_and_course).as_json}
end

get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(organization, course)
    .find_by(exercise_student_progress_query.merge('exercise.id' => exercise_id)).as_json
end

get '/permissions' do
  authorize! :teacher

  {permissions: permissions}
end

post '/courses/:course/students' do
  authorize! :janitor
  ensure_course_existence!
  Classroom::Collection::CourseStudents.for(organization).ensure_new! json_body['email'], course_slug

  json = {student: json_body.merge(uid: json_body['email']), course: {slug: course_slug}}
  Classroom::Collection::CourseStudents.for(organization).insert! json
  Student.create!(with_organization_and_course json[:student])

  Mumukit::Nuntius::Publisher.publish_resubmissions(uid: json[:student][:uid], tenant: tenant)

  perm = current_user.permissions
  perm.add_permission!(:student, course_slug)
  User.upsert_permissions! json[:student][:uid], perm
  Mumukit::Nuntius::EventPublisher.publish 'UserChanged', user: json[:student].merge(permissions: perm)

  {status: :created}
end
