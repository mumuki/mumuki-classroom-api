require 'sinatra'
require 'sinatra/cross_origin'
require 'sinatra/subdomain'

require 'mumukit/auth'

require_relative '../lib/classroom'
 configure do
  enable :cross_origin
  set :allow_methods, [:get, :put, :post, :options, :delete]
  set :show_exceptions, false

  Mongo::Logger.logger = ::Logger.new('mongo.log')
end


subdomain do

  helpers do
    def json_body
      @json_body ||= JSON.parse(request.body.read) rescue nil
    end

    def permissions
      @permissions ||= parse_token.permissions 'classroom'
    end

    def parse_token
      token = Mumukit::Auth::Token.decode_header(authorization_header)
      token.tap &:verify_client!
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
      tenant = subdomain.present?? subdomain : 'central'
      env['mongo_client'] = Mongo::Client.new([ '127.0.0.1:27017' ], database: tenant)
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

  get '/api/courses' do
    grants = permissions.to_s.gsub(/[:]/, '|').gsub(/[*]/, '.*')
    { courses: Course.all(grants, env) }
  end

  get '/api/courses/:org/:course' do
    protect!
    guides = GuideProgress.by_course(slug('course'), env)
    { course_guides: guides.as_json.map { |guide| guide['guide']}.to_set }
  end

  get '/api/guide_progress/:org/:repo/:student_id/:exercise_id' do
    { exercise_progress: GuideProgress.exercise_by_student(slug('repo'), params['student_id'].to_i, params['exercise_id'].to_i, env) }
  end

  get '/api/guide_progress/:org/:repo' do
    { guides_progress: GuideProgress.by_slug(slug('repo'), env).select { |guide| permissions.allows? guide['course']['slug'] } }
  end

  post '/events/submissions' do
    GuideProgress.update! json_body, env
  end
end
