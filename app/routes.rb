require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/service/routes'
require 'mumukit/service/routes/auth'

require_relative '../lib/classroom'

configure do
  set :app_name, 'classroom'
  set :root, File.join(__dir__, '..')
end

helpers do

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

  def route_slug_parts
    [tenant, course].compact
  end

  def course_slug
    @course_slug ||= Mumukit::Service::Slug.new(tenant, course).to_s
  end

  def repo_slug
    @repo_slug ||= Mumukit::Service::Slug.new(params[:organization], params[:repository]).to_s
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
    permissions = Mumukit::Auth::Store.get uid
    permissions.send("#{method}_permission!", 'student', course_slug)
    Classroom::Collection::Students.for(course).find_by({uid: uid}).try do |user|
      user_as_json = user.as_json(only: [:first_name, :last_name, :email])
      user_to_notify = user_as_json.merge(uid: uid, permissions: permissions)
      Mumukit::Nuntius::EventPublisher.publish('UserChanged', user_to_notify)
    end
  end

  def notify_upsert_exam(exam_id)
    Mumukit::Nuntius::EventPublisher.publish('UpsertExam', tenantized_json_body.merge(exam_id))
  end

end

before do
  Classroom::Database.connect! tenant
  set_locale! organization_json if organization_json
end

after do
  Classroom::Database.disconnect!
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
  protect! :teacher
  Classroom::Collection::Students.for(course).all.as_json
end

post '/courses/:course/students/:uid' do
  protect! :janitor
  Mumukit::Nuntius::Publisher.publish_resubmissions(uid: uid, tenant: tenant)
  {status: :created}
end

post '/courses/:course/students/:uid/detach' do
  protect! :janitor
  Classroom::Collection::Students.for(course).detach!(uid)
  update_and_notify_student_metadata(uid, 'remove')
  {status: :updated}
end

post '/courses/:course/students/:uid/attach' do
  protect! :janitor
  Classroom::Collection::Students.for(course).attach!(uid)
  update_and_notify_student_metadata(uid, 'add')
  {status: :updated}
end

get '/courses/:course/student/:uid' do
  protect! :teacher

  Classroom::Collection::Students.for(course).find_by(uid: uid).as_json
end

get '/courses/:course/guides' do
  protect! :teacher
  Classroom::Collection::Guides.for(course).all.as_json
end

get '/courses/:course/guides/:organization/:repository' do
  protect! :teacher
  Classroom::Collection::GuideStudentsProgress.for(course).where('guide.slug' => repo_slug).as_json
end

get '/courses/:course/guides/:organization/:repository/:uid' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .where(exercise_student_progress_query).as_json
end

get '/courses/:course/progress' do
  protect! :teacher
  Classroom::Collection::ExerciseStudentProgress.for(course).all.as_json
end

get '/courses/:course/guides/:organization/:repository/:uid/:exercise_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .find_by(exercise_student_progress_query.merge('exercise.id' => exercise_id)).as_json
end

get '/permissions' do
  permissions.protect! :teacher, Mumukit::Auth::Slug.join_s(tenant, '_')

  {permissions: permissions }
end
