require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/auth'
require 'mumukit/nuntius'

require_relative './request'
require_relative '../lib/classroom'

configure do
  enable :cross_origin
  set :allow_methods, [:get, :put, :post, :options, :delete]
  set :show_exceptions, false

  Mongo::Logger.logger = ::Logger.new('mongo.log')
end

helpers do
  def json_body
    @json_body ||= JSON.parse(request.body.read) rescue nil
  end

  def permissions
    @permissions ||= token.permissions 'classroom'
  end

  def token
    @token ||= Mumukit::Auth::Token.decode_header(authorization_header).tap(&:verify_client!)
  end

  def authorization_header
    env['HTTP_AUTHORIZATION']
  end

  def protect!
    permissions.protect!(course_slug)
  end


  def course_slug
    @course_slug ||= "#{request.first_subdomain}/#{params['course']}"
  end

  def repo_slug
    @repo_slug ||= "#{params['org']}/#{params['repo']}"
  end

  def set_mongo_connection
    Classroom::Database.tenant = request.first_subdomain
  end

  def convert(parameters)
    parameters.as_json['parameters']
  end

end

before do
  content_type 'application/json', 'charset' => 'utf-8'
  set_mongo_connection
end

after do
  Classroom::Database.client.close
end

after do
  error_message = env['sinatra.error']
  if error_message.blank?
    response.body = response.body.to_json
  else
    response.body = {message: env['sinatra.error'].message}.to_json
  end
end

error JSON::ParserError do
  halt 400
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

error Mumukit::Auth::InvalidTokenError do
  halt 400
end

error Mumukit::Auth::UnauthorizedAccessError do
  halt 403
end

options '*' do
  response.headers['Allow'] = settings.allow_methods.map { |it| it.to_s.upcase }.join(',')
  response.headers['Access-Control-Allow-Headers'] = 'X-Mumuki-Auth-Token, X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization'
  200
end

get '/courses' do
  grants = permissions.to_s.gsub(/[:]/, '|').gsub(/[*]/, '.*')
  if grants.to_s == ''
    return {courses: []}
  else
    {courses: Classroom::Course.all(grants)}
  end
end

post '/courses' do
  course_slug = json_body['slug']
  permissions.protect!(course_slug)

  Classroom::Course.ensure_new! course_slug

  Classroom::Course.insert!(
      code: json_body['code'],
      days: json_body['days'],
      period: json_body['period'],
      shifts: json_body['shifts'],
      description: json_body['description'],
      slug: course_slug)

  {status: :created}
end

get '/courses/:course' do
  protect!
  {course_guides: Classroom::GuideProgress.by_course(course_slug)}
end

post '/courses/:course/students' do
  Classroom::Course.ensure_exist! course_slug

  Classroom::CourseStudent.insert!(
      student: {first_name: json_body['first_name'],
                last_name: json_body['last_name'],
                social_id: token.jwt['sub']},
      course: {slug: course_slug})

  {status: :created}
end

get '/guide_progress/:course/:org/:repo/:student_id/:exercise_id' do
  {exercise_progress: Classroom::GuideProgress.exercise_by_student(course_slug, repo_slug, params['student_id'], params['exercise_id'].to_i)}
end

get '/guide_progress/:course/:org/:repo' do
  {
      guide: Classroom::GuideProgress.guide_data(repo_slug, course_slug)['guide'],
      progress: Classroom::GuideProgress.by_slug_and_course(repo_slug, course_slug).select { |guide| permissions.allows? guide['course']['slug'] }
  }
end

get '/students/:course' do
  protect!
  {students: Classroom::GuideProgress.students_by_course_slug(course_slug)}
end

post '/events/submissions' do
  Classroom::GuideProgress.update! json_body
  {status: :created}
end

post '/comment/:course' do
  protect!
  Classroom::Comment.insert! json_body
  Mumukit::Nuntius::Publisher.publish_comments json_body.merge(tenant: request.first_subdomain)
  {status: :created}
end

get '/comments/:submission_id' do
  protect!
  {comments: Classroom::Comment.where(submission_id: params[:submission_id].to_i)}
end

get '/followers/:email' do
  protect!
  {followers: Classroom::Follower.where(email: params[:email])}
end

post '/follower/:course' do
  protect!
  Classroom::Follower.add_follower json_body
  {status: :created}
end

delete '/follower/:course/:email/:social_id' do
  protect!
  Classroom::Follower.remove_follower "course" => params[:course], "email" => params[:email], "social_id" => params[:social_id]
  {status: :created}
end

get '/ping' do
  {message: 'pong!'}
end
