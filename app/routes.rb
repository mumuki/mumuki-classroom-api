require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/service/routes'

require_relative './session_store'
require_relative './omniauth'
require_relative '../lib/classroom'


configure do
  enable :cross_origin
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
      .select { |key, value| current_organization.login_method_present? key.to_s, value }
      .keys
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
    Course.ensure_exist! with_organization(slug: course_slug)
  end

  def ensure_student_not_exists!
    Student.ensure_not_exists! with_organization_and_course uid: json_body[:email]
  end

  def set_locale!(org)
    I18n.locale = org['locale'].include?('-') ? org['locale'].split('-').first : org['locale']
  end

  def organization_json
    @organization_json ||= current_organization.as_json
  end

  def current_organization
    @current_organization ||= Organization.find_by(name: organization)
  end

  def update_and_notify_student_metadata(uid, method)
    user = User.find_by_uid!(uid)
    permissions = user.permissions
    permissions.send("#{method}_permission!", 'student', course_slug)
    user.upsert_permissions! permissions
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

  def order_by
    params[:order_by] || :asc
  end

  def paginated_params
    {
      page: page,
      sort_by: sort_by,
      order_by: order_by,
      per_page: per_page,
      with_detached: with_detached
    }
  end

  def with_detached_and_search(params)
    params
      .merge_unless(with_detached, 'detached': {'$exists': false})
      .merge_unless(query.empty?, '$text': {'$search': params})
  end

end

before do
  set_locale! organization_json if organization_json
end

require_relative './routes/courses'
require_relative './routes/guides'
require_relative './routes/messages'
require_relative './routes/errors'
require_relative './routes/exams'
require_relative './routes/followers'
require_relative './routes/organization'
require_relative './routes/ping'
require_relative './routes/teachers'
require_relative './routes/students'
require_relative './routes/permissions'
require_relative './routes/notifications'
require_relative './routes/suggestions'
require_relative './routes/manual_evaluation'
