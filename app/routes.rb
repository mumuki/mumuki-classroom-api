require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/service/routes'

require_relative './session_store'
require_relative './omniauth'
require_relative '../lib/classroom'

configure do
  set :app_name, 'classroom'
  set :static, true
  set :public_folder, 'public'
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

  def login_settings
    Mumukit::Login::Settings.new mumukit_login_methods
  end

  def mumukit_login_methods
    Mumukit::Login::Settings::LOCK_LOGIN_METHODS
      .select { |key, _| Classroom::Collection::Organizations.login_method_present? organization_json, key.to_s }
      .keys
  end

  def exercise_student_progress_query
    {'guide.slug': repo_slug, 'student.uid': uid}
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

  def ensure_student_not_exists!
    Student.ensure_not_exists! with_organization uid: json_body[:email]
  end

  def set_locale!(org)
    I18n.locale = org['locale'].include?('-') ? org['locale'].split('-').first : org['locale']
  end

  def organization_json
    @organization_json ||= Organization.find_by(name: organization).as_json
  end

  def update_and_notify_student_metadata(uid, method)
    user = User.find_by_uid!(uid)
    user.send("#{method}_permission!", 'student', course_slug)
    user.upsert_permissions! user.permissions
    user.notify!
  end

  def notify_upsert_exam(exam_id)
    Mumukit::Nuntius.notify_event! 'UpsertExam', tenantized_json_body.except(:social_ids).merge(exam_id)
  end

end

before do
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
  {guide_students_progress: GuideProgress.where(with_organization_and_course 'student.uid': uid).as_json}
end

post '/courses/:course/students/:uid' do
  authorize! :janitor
  Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
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
  {guide_students_progress: GuideProgress.where(with_organization_and_course 'guide.slug': repo_slug).as_json}
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
  Assignment.find_by!(with_organization_and_course exercise_student_progress_query.merge('exercise.eid': exercise_id)).as_json
end

get '/permissions' do
  authorize! :teacher

  {permissions: permissions}
end

post '/courses/:course/students' do
  authorize! :janitor
  ensure_course_existence!
  ensure_student_not_exists!

  json = {student: json_body.merge(uid: json_body[:email]), course: {slug: course_slug}}
  uid = json[:student][:uid]

  Student.create!(with_organization_and_course json[:student])

  perm = User.where(uid: uid).first_or_create!(json[:student].except(:first_name, :last_name)).permissions
  perm.add_permission!(:student, course_slug)
  User.upsert_permissions! uid, perm

  Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
  Mumukit::Nuntius.notify_event! 'UserChanged', user: json[:student].merge(permissions: perm)

  {status: :created}
end
