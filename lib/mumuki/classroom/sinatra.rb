require 'sinatra/base'
require 'sinatra/cross_origin'

class Mumuki::Classroom::App < Sinatra::Application
  configure do
    enable :cross_origin
    set :allow_methods, [:get, :put, :post, :options, :delete]
    set :show_exceptions, false

    set :app_name, 'classroom'
    set :static, true
    set :public_folder, 'public'

    use ::Rack::CommonLogger, Rails.logger
  end


  helpers do
    Mumukit::Login.configure_controller! self

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

    def slug
      if route_slug_parts.present?
        Mumukit::Auth::Slug.join(*route_slug_parts)
      elsif subject
        Mumukit::Auth::Slug.parse(subject.slug)
      elsif json_body
        Mumukit::Auth::Slug.parse(json_body['slug'])
      else
        raise Mumukit::Auth::InvalidSlugFormatError.new('Slug not available')
      end
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

    def tenant
      Mumukit::Platform.organization_name(request)
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
      raise Mumuki::Domain::NotFoundError, "Course #{course_slug} does not exist" unless Course.exists?(slug: course_slug)
    end

    def ensure_student_not_exists!
      Mumuki::Classroom::Student.ensure_not_exists! with_organization_and_course uid: json_body[:email]
    end

    def set_locale!
      I18n.locale = current_organization.locale
    end

    def organization_json
      @organization_json ||= current_organization.as_json
    end

    def current_organization
      @current_organization ||= Organization.find_by(name: organization)
    end

    def update_and_notify_student_metadata(uid, method, *slugs)
      user = User.find_by_uid!(uid)
      permissions = user.permissions
      permissions.send("#{method}_permission!", 'student', *slugs)
      user.update! permissions: permissions
      user.notify!
    end

    def notify_upsert_exam(exam_id)
      body = tenantized_json_body.except(:social_ids).merge(exam_id)
      Exam.import_from_resource_h! body
      Mumukit::Nuntius.notify_event! 'UpsertExam', body
    end

    def page
      (params[:page] || 1).to_i - 1
    end

    def per_page
      (params[:per_page] || 30).to_i
    end

    def sort_by
      params[:sort_by] || :name
    end

    def with_detached
      params[:with_detached].boolean_value
    end

    def query
      params[:q] || ''
    end

    def query_criteria
      params[:query_criteria]
    end

    def query_operand
      params[:query_operand]
    end

    def order_by
      params[:order_by] || :asc
    end

  end


  before do
    content_type 'application/json', 'charset' => 'utf-8'
  end

  after do
    error_message = env['sinatra.error']
    if response.body.is_a?(Array)&& response.body[0].is_a?(String)
      if content_type != 'application/csv'
        content_type 'text/html'
        response.body[0] = <<HTML
    <html>
      <body>
        #{response.body[0]}
      </body>
    </html>
HTML
      end
      response.body = response.body[0]
    elsif error_message.blank?
      response.body = response.body.to_json
    else
      response.body = {message: env['sinatra.error'].message}.to_json
    end
  end

  error JSON::ParserError do
    halt 400
  end

  error ActiveRecord::RecordInvalid do
    halt 400
  end

  error ActiveRecord::RecordNotFound do
    halt 404
  end

  error Mumukit::Auth::InvalidTokenError do
    halt 401
  end

  error Mumukit::Auth::UnauthorizedAccessError do
    halt 403
  end

  error Mumukit::Auth::InvalidSlugFormatError do
    halt 400
  end

  before do
    set_locale! if current_organization
  end

  options '*' do
    response.headers['Allow'] = settings.allow_methods.map { |it| it.to_s.upcase }.join(',')
    response.headers['Access-Control-Allow-Headers'] = 'X-Mumuki-Auth-Token, X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization'
    200
  end
end

require_relative './sinatra/errors'
require_relative './sinatra/pagination'
require_relative './sinatra/courses'
require_relative './sinatra/guides'
require_relative './sinatra/messages'
require_relative './sinatra/exams'
require_relative './sinatra/followers'
require_relative './sinatra/organization'
require_relative './sinatra/ping'
require_relative './sinatra/teachers'
require_relative './sinatra/students'
require_relative './sinatra/permissions'
require_relative './sinatra/notifications'
require_relative './sinatra/suggestions'
require_relative './sinatra/manual_evaluation'
require_relative './sinatra/searching'
