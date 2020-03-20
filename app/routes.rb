require 'sinatra'
require 'sinatra/namespace'
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

  def ensure_students_not_exist!
    students_uids = students.map { |it| it[:email] }
    Student.ensure_not_exists! with_organization_and_course(uid: {'$in': students_uids })
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
    update_and_notify_user_metadata(User.find_by_uid!(uid), method, *slugs)
  end

  def update_and_notify_user_metadata(user, method, *slugs)
    permissions = user.permissions
    permissions.send("#{method}_permission!", 'student', *slugs)
    user.upsert_permissions! permissions
    user.notify!
  end

  def notify_upsert_exam(exam_id)
    Mumukit::Nuntius.notify_event! 'UpsertExam', tenantized_json_body.except(:social_ids).merge(exam_id)
  end

  def notify_exam_students!(exam, diff)
    Mumukit::Nuntius.notify_event! 'UpsertExamStudents', diff.merge(eid: exam.eid)
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
    aggregation = Student.where(matcher).project(projection)
    pipeline_with_sort_criterion = aggregation.pipeline << {'$sort': {passed_count: -1, passed_with_warnings_count: -1, failed_count: -1, last_name: 1, first_name: 1}}
    json = Student.collection.aggregate(pipeline_with_sort_criterion).as_json
    content_type 'application/csv'
    csv_with_headers(Classroom::Reports::Formats.format_report('csv', json), projection)
  end

  def notify_user!(user)
    Mumukit::Nuntius.notify_event! 'UserChanged', user: user.as_platform_json.merge(verified_first_name: user.first_name, verified_last_name: user.last_name)
  end
end

before do
  set_locale! if current_organization
end

require_relative './routes/errors'
require_relative './routes/pagination'
require_relative './routes/courses'
require_relative './routes/guides'
require_relative './routes/messages'
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
require_relative './routes/massive'
