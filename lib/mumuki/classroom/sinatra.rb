require 'sinatra/base'
require 'sinatra/namespace'
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

    # FIXME only provisional
    def with_current_organization(hash = {})
      {organization: current_organization}.merge hash.except(:organization)
    end

    # FIXME only provisional
    def with_current_organization_and_course(hash = {})
      with_current_organization.merge(course: current_course).merge hash.except(:organization, :course)
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
      Course.locate! course_slug
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
      @current_organization ||= Organization.locate!(organization).switch!
    end

    def current_course
      @current_course ||= Course.locate!(course_slug)
    end

    def update_and_notify_student_metadata(uid, method, *slugs)
      user = User.find_by_uid!(uid)
      permissions = user.permissions
      permissions.send("#{method}_permission!", 'student', *slugs)
      user.update! permissions: permissions
      user.notify!
    end

    def notify_upsert_exam(exam_id)
      Mumukit::Nuntius.notify_event! 'UpsertExam', tenantized_json_body.except(:social_ids).merge(exam_id)
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

    def csv_projection_for(projection)
      projection.transform_values do |val|
        next val if val == 0
        {'$ifNull': [val, nil]}
      end
    end

    def group_report_projection
      {
        '_id': 0,
        'last_name': '$last_name',
        'first_name': '$first_name',
        'email': '$email',
        'personal_id': '$personal_id',
        'detached': {'$eq': ['$detached', true]},
        'created_at': '$created_at',
        'last_submission_date': '$last_assignment.submission.created_at',
        'passed_count': '$stats.passed',
        'passed_with_warnings_count': '$stats.passed_with_warnings',
        'failed_count': '$stats.failed',
        'last_lesson_type': '$last_assignment.guide.parent.type',
        'last_lesson_name': '$last_assignment.guide.parent.name',
        'last_exercise_number': '$last_assignment.exercise.number',
        'last_exercise_name': '$last_assignment.exercise.name',
        'last_chapter': '$last_assignment.guide.parent.chapter.name',
      }
    end

    def group_report(matcher, projection)
      projection = csv_projection_for projection
      aggregation = Mumuki::Classroom::Student.where(matcher).project(projection)
      pipeline_with_sort_criterion = aggregation.pipeline << {'$sort': {passed_count: -1, passed_with_warnings_count: -1, failed_count: -1, last_name: 1, first_name: 1}}
      json = Mumuki::Classroom::Student.collection.aggregate(pipeline_with_sort_criterion).as_json
      content_type 'application/csv'
      csv_with_headers(Mumuki::Classroom::Reports::Formats.format_report('csv', json), projection)
    end
  end


  before do
    content_type 'application/json', 'charset' => 'utf-8'
  end

  after do
    error_message = env['sinatra.error']
    if response.body.is_a?(Array) && response.body[0].is_a?(String)
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
require_relative './sinatra/massive'
