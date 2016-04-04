require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/auth'

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
    permissions.protect!(slug(:course))
  end

  def slug(type)
    "#{org}/#{params[type]}"
  end

  def org
    params['org']
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
  slug = "#{request.first_subdomain}/#{json_body['name']}"
  permissions.protect!(slug)

  Classroom::Course.ensure_new! slug

  Classroom::Course.insert!(
      name: json_body['name'],
      description: json_body['description'],
      slug: slug)

  {status: :created}
end

get '/courses/:org/:course' do
  protect!
  {course_guides: Classroom::GuideProgress.by_course(slug('course'))}
end

post '/courses/:course/students' do
  slug = "#{request.first_subdomain}/#{params['course']}"
  Classroom::Course.ensure_exist! slug

  Classroom::CourseStudent.insert!(
      student: {first_name: json_body['first_name'],
                last_name: json_body['last_name'],
                social_id: token.jwt['sub']},
      course: {slug: slug})

  {status: :created}
end

get '/guide_progress/:org/:course/:repo/:student_id/:exercise_id' do
  course = "#{request.first_subdomain}/#{params['course']}"
  {exercise_progress: Classroom::GuideProgress.exercise_by_student(course, slug('repo'), params['student_id'], params['exercise_id'].to_i)}
end

get '/guide_progress/:org/:course/:repo' do
  course = "#{request.first_subdomain}/#{params['course']}"
  {
    guide: Classroom::GuideProgress.guide_data(slug('repo'), course)['guide'],
    progress: Classroom::GuideProgress.by_slug_and_course(slug('repo'), course).select { |guide| permissions.allows? guide['course']['slug']}
  }
end

get '/students/:org/:course' do
  protect!
  { students: Classroom::GuideProgress.students_by_course_slug(slug(:course)) }
end

post '/events/submissions' do
  Classroom::GuideProgress.update! json_body
  {status: :created}
end

post '/comment' do
  protect!
  Classroom::Comment.insert! json_body
  Classroom::Rabbit.publish_comments json_body.merge(tenant: request.first_subdomain)
  {status: :created}
end

get '/comments/:exercise_id' do
  protect!
  {comments: Classroom::Comment.where(exercise_id: params[:exercise_id].to_i)}
end

get '/ping' do
  {message: 'pong!'}
end
