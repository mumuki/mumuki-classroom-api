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
end

helpers do
  def authenticate!
    halt 401 unless current_user?
  end

  def authorization_slug
    slug
  end

  def permissions(client = :auth0)
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
      .select { |_, value| organization_json['lock_json']['connections'].include? value }
      .keys
  end

  def exercise_student_progress_query
    {'guide.slug': repo_slug, 'student.uid': uid}
  end

  def by_permissions(key, client = :auth0, &query)
    grants = permissions_to_regex client
    if grants.to_s.blank?
      {}.tap { |it| it[key] = [] }
    else
      query.call(grants)
    end
  end

  def permissions_to_regex(client)
    permissions(client).to_s.gsub(/[:]/, '|').gsub(/[*]/, '.*')
  end

  def tenant
    request.first_subdomain
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
    Classroom::Collection::Courses.ensure_exist! course_slug
  end

  def ensure_course_student_existence!(uid)
    Classroom::Collection::CourseStudents.ensure_exist! uid, course_slug
  end

  def set_locale!(org)
    I18n.locale = org['locale']
  end

  def organization_json
    @organization_json ||= Classroom::Collection::Organizations.find_by(name: tenant).as_json
  end

  def update_and_notify_student_metadata(uid, method)
    permissions = Classroom::Collection::Users.find_by_uid!(uid).permissions
    permissions.send("#{method}_permission!", 'student', course_slug)
    Classroom::Collection::Students.for(course).find_by({uid: uid}).try do |user|
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
  Classroom::Database.connect! tenant
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
  Classroom::Collection::Students.for(course).all.as_json
end

get '/api/courses/:course/students' do
  authorize! :teacher
  Classroom::Collection::Students.for(course).all.as_json
end

get '/api/courses/:course/students/:uid' do
  authorize! :teacher
  Classroom::Collection::GuideStudentsProgress.for(course).where('student.uid': uid).as_json
end

post '/courses/:course/students/:uid' do
  authorize! :janitor
  Mumukit::Nuntius::Publisher.publish_resubmissions(uid: uid, tenant: tenant)
  {status: :created}
end

post '/courses/:course/students/:uid/detach' do
  authorize! :janitor
  Classroom::Collection::Students.for(course).detach!(uid)
  update_and_notify_student_metadata(uid, 'remove')
  {status: :updated}
end

post '/courses/:course/students/:uid/attach' do
  authorize! :janitor
  Classroom::Collection::Students.for(course).attach!(uid)
  update_and_notify_student_metadata(uid, 'add')
  {status: :updated}
end

get '/courses/:course/student/:uid' do
  authorize! :teacher

  Classroom::Collection::Students.for(course).find_by(uid: uid).as_json
end

get '/courses/:course/guides' do
  authorize! :teacher
  Classroom::Collection::Guides.for(course).all.as_json
end

get '/api/courses/:course/guides' do
  authorize! :teacher
  Classroom::Collection::Guides.for(course).all.as_json
end

get '/courses/:course/guides/:organization/:repository' do
  authorize! :teacher
  Classroom::Collection::GuideStudentsProgress.for(course).where('guide.slug' => repo_slug).as_json
end

get '/courses/:course/guides/:organization/:repository/:uid' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .where(exercise_student_progress_query).as_json
end

get '/courses/:course/progress' do
  authorize! :teacher
  Classroom::Collection::ExerciseStudentProgress.for(course).all.as_json
end

get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .find_by(exercise_student_progress_query.merge('exercise.id' => exercise_id)).as_json
end

get '/permissions' do
  authorize! :teacher

  {permissions: permissions}
end

post '/courses/:course/students' do
  authorize! :janitor

  ensure_course_existence!
  Classroom::Collection::CourseStudents.ensure_new! json_body['email'], course_slug
  Classroom::Collection::Students.for(course).ensure_new! json_body['email']

  json = {student: json_body.merge(uid: json_body['email']), course: {slug: course_slug}}
  Classroom::Collection::CourseStudents.insert! json.wrap_json
  Classroom::Collection::Students.for(course).insert!(json[:student].wrap_json)

  Mumukit::Nuntius::Publisher.publish_resubmissions(uid: json[:student][:uid], tenant: tenant)

  perm = Classroom::Collection::Users.upsert_permissions! json[:student][:uid], {student: course_slug}
  Mumukit::Nuntius::EventPublisher.publish 'UserChanged', user: json[:student].merge(permissions: perm)

  {status: :created}
end
