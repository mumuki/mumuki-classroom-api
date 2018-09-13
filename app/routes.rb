require 'sinatra'
require 'sinatra/cross_origin'
require 'mumukit/service/routes'

require_relative './session_store'
require_relative '../lib/classroom'


configure do
  enable :cross_origin
  set :app_name, 'classroom'
  set :static, true
  set :public_folder, 'public'
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
    Course.ensure_exist! with_organization(slug: course_slug)
  end

  def ensure_student_not_exists!
    Student.ensure_not_exists! with_organization_and_course uid: json_body[:email]
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
  set_locale! if current_organization
end

require_relative './routes/pagination'
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
require_relative './routes/searching'
