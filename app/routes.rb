require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/auth'
require 'mumukit/nuntius'
require 'mumukit/service/routes'
require 'mumukit/service/routes/auth'

require_relative './request'
require_relative '../lib/classroom'

configure do
  set :app_name, 'classroom'
end

helpers do

  def permissions_to_regex
    permissions.to_s.gsub(/[:]/, '|').gsub(/[*]/, '.*')
  end

  def tenant
    request.first_subdomain
  end

  def route_slug_parts
    [tenant, params[:course]].compact
  end

  def course_slug
    @course_slug ||= Mumukit::Service::Slug.new(tenant, params[:course]).to_s
  end

  def repo_slug
    @repo_slug ||= Mumukit::Service::Slug.new(params[:organization], params[:repository]).to_s
  end

  def set_mongo_connection
    Classroom::Database.tenant = tenant
  end

end

before do
  set_mongo_connection
end

after do
  Classroom::Database.client.close
end

error Classroom::CourseExistsError do
  halt 400
end

error Classroom::CourseNotExistsError do
  halt 400
end

error Classroom::CourseStudentNotExistsError do
  halt 400
end

get '/courses' do
  grants = permissions_to_regex
  if grants.to_s.blank?
    { courses: [] }
  else
    Classroom::Collection::Courses.all(grants).as_json
  end
end

post '/courses' do
  course_slug = json_body['slug']
  permissions.protect!(course_slug)

  Classroom::Collection::Courses.ensure_new! course_slug

  json = {code: json_body['code'],
    days: json_body['days'],
    period: json_body['period'],
    shifts: json_body['shifts'],
    description: json_body['description'],
    slug: course_slug}

  Classroom::Collection::Courses.insert!(json.wrap_json)

  {status: :created}
end

get '/courses/:course' do
  protect!
  {course_guides: Classroom::Collection::GuidesProgress.by_course(course_slug)}
end

post '/courses/:course/students' do
  Classroom::Collection::Courses.ensure_exist! course_slug

  json ={student: {first_name: json_body['first_name'],
                   last_name: json_body['last_name'],
                   social_id: token.jwt['sub']},
         course: {slug: course_slug}}

  Classroom::Collection::CourseStudents.insert!(json.wrap_json)

  {status: :created}
end

get '/guide_progress/:course/:organization/:repository/:student_id/:exercise_id' do
  {exercise_progress: Classroom::Collection::GuidesProgress.exercise_by_student(course_slug, repo_slug, params['student_id'], params['exercise_id'].to_i)}
end

get '/guide_progress/:course/:organization/:repository' do
  {
      guide: Classroom::Collection::GuidesProgress.guide_data(repo_slug, course_slug).guide,
      progress: Classroom::Collection::GuidesProgress.by_slug_and_course(repo_slug, course_slug).
        as_json[:guides_progress].select { |guide| permissions.allows? guide['course']['slug'] }
  }
end

get '/students/:course' do
  protect!
  { students: Classroom::Collection::GuidesProgress.students_by_course_slug(course_slug) }
end

post '/comment/:course' do
  protect!
  json = json_body.wrap_json
  Classroom::Collection::Comments.insert!(json)
  Mumukit::Nuntius::Publisher.publish_comments json.merge(tenant: tenant)
  { status: :created }
end

get '/comments/:course/:exercise_id' do
  protect!
  Classroom::Collection::Comments.where(exercise_id: params[:exercise_id].to_i).as_json
end

get '/followers/:email' do
  grants = permissions_to_regex
  if grants.to_s.blank?
    { followers: [] }
  else
    Classroom::Collection::Followers.where(email: params[:email], course: { '$regex' => grants }).as_json
  end
end

post '/follower/:course' do
  protect!
  json_body['course'] = course_slug
  Classroom::Collection::Followers.add_follower json_body
  {status: :created}
end

delete '/follower/:course/:email/:social_id' do
  protect!
  Classroom::Collection::Followers.remove_follower 'course' => course_slug, 'email' => params[:email], 'social_id' => params[:social_id]
  {status: :created}
end

get '/ping' do
  {message: 'pong!'}
end
