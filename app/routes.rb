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

  def course
    params[:course]
  end

  def student_id
    params[:student_id]
  end

  def exercise_id
    params[:exercise_id].to_i
  end

  def exercise_student_progress_query
    {'guide.slug' => repo_slug, 'student.social_id' => student_id}
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

  def set_mongo_connection
    Classroom::Database.organization = tenant
  end

  def tenantized_json_body
    json_body.merge(tenant: tenant)
  end

  def ensure_course_existence!
    Classroom::Collection::Courses.ensure_exist! course_slug
  end

  def ensure_course_student_existence!(social_id)
    Classroom::Collection::CourseStudents.ensure_exist! social_id, course_slug
  end

  def set_locale!(org)
    I18n.locale = org['locale']
  end

  def organization_json
    @organization_json ||= Classroom::Collection::Organizations.find_by(name: tenant).as_json
  end

end

before do
  set_mongo_connection
  set_locale! organization_json if organization_json
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

error Classroom::StudentExistsError do
  halt 400
end

error Classroom::CourseStudentExistsError do
  halt 400
end

error Classroom::StudentNotExistsError do
  halt 400
end

error Classroom::TeacherExistsError do
  halt 400
end

error Mumukit::Auth::EmailNotRegistered do
  halt 400
end

get '/courses' do
  by_permissions :courses do |grants|
    Classroom::Collection::Courses.allowed(grants).as_json
  end
end

post '/courses' do
  permissions.protect! json_body['slug']

  Classroom::Collection::Courses.ensure_new! json_body['slug']
  Classroom::Collection::Courses.insert! json_body.wrap_json

  {status: :created}
end

get '/courses/:course/students' do
  protect!
  Classroom::Collection::Students.for(course).all.as_json
end

post '/courses/:course/students' do
  social_id = token.jwt['sub']

  ensure_course_existence!
  Classroom::Collection::CourseStudents.ensure_new! social_id, course_slug
  Classroom::Collection::Students.for(course).ensure_new! social_id, json_body['email']

  json = {student: json_body.merge(social_id: social_id), course: {slug: course_slug}}
  Classroom::Collection::CourseStudents.insert! json.wrap_json
  Classroom::Collection::Students.for(course).insert!(json[:student].wrap_json)

  Mumukit::Nuntius::Publisher.publish_resubmissions(social_id: social_id, tenant: tenant)
  Mumukit::Auth::User.new(token.jwt['sub']).add_permission!('atheneum', "#{tenant}/*")

  {status: :created}
end

post '/courses/:course/students/:student_id' do
  protect!
  Mumukit::Nuntius::Publisher.publish_resubmissions(social_id: student_id, tenant: tenant)
  {status: :created}
end

delete '/courses/:course/students/:student_id' do
  protect!
  Classroom::Collection::ExerciseStudentProgress.for(course).delete_student!(student_id)
  Classroom::Collection::Students.for(course).delete!(student_id)
  Classroom::Collection::CourseStudents.delete_student!(course_slug, student_id)
  Classroom::Collection::GuideStudentsProgress.for(course).delete_student!(student_id)
  Classroom::Collection::Followers.for(course).delete_follower!(course_slug, student_id)
  {status: :deleted}
end

post '/courses/:course/students/:student_id/detach' do
  protect!
  Mumukit::Auth::User.new(student_id).try do |user|
    Classroom::Collection::Students.for(course).detach!(student_id)
    Classroom::Collection::ExerciseStudentProgress.for(course).detach_student!(student_id)
    Classroom::Collection::GuideStudentsProgress.for(course).detach_student!(student_id)
    user.remove_permission!('atheneum', "#{tenant}/*")
    Mumukit::Nuntius::CommandPublisher.publish('atheneum', 'UpdateUserMetadata', { social_id: student_id })
  end
  {status: :updated}
end

post '/courses/:course/students/:student_id/attach' do
  protect!
  Classroom::Collection::Students.for(course).attach!(student_id)
  Classroom::Collection::ExerciseStudentProgress.for(course).attach_student!(student_id)
  Classroom::Collection::GuideStudentsProgress.for(course).attach_student!(student_id)
  user.add_permission!('atheneum', "#{tenant}/*")
  Mumukit::Nuntius::CommandPublisher.publish('atheneum', 'UpdateUserMetadata', { social_id: student_id })
  {status: :updated}
end

post '/courses/:course/students/:student_id/transfer' do
  protect!
  Classroom::Collection::Students
    .for(course)
    .transfer(student_id, tenant, json_body['destination'])
  {status: :updated}
end

get '/courses/:course/student/:social_id' do
  protect!

  Classroom::Collection::Students.for(course).find_by(social_id: params[:social_id]).as_json
end

put '/courses/:course/student' do
  protect!

  ensure_course_existence!
  ensure_course_student_existence!(json_body['social_id'])
  json = {first_name: json_body['first_name'], last_name: json_body['last_name'], social_id: json_body['social_id'], course_slug: course_slug}
  Classroom::Collection::CourseStudents.update!(json)
  Classroom::Collection::Students.for(course).update!(json)

  {status: :updated}
end

get '/courses/:course/teachers' do
  protect!
  Classroom::Collection::Teachers.for(course).all.as_json
end

post '/courses/:course/teachers' do
  protect!

  Mumukit::Auth::User.from_email(json_body['email']).tap do |user|
    ensure_course_existence!
    Classroom::Collection::Teachers.for(course).ensure_new! user.social_id, json_body['email']
    Classroom::Collection::Teachers.for(course).insert!(json_body.merge(image_url: user.user['picture'], social_id: user.social_id).wrap_json)
    Classroom::Collection::Students.for(course).delete!(user.social_id)

    user.add_permission!('classroom', course_slug)
    user.add_permission!('atheneum', "#{tenant}/*")
  end

  {status: :created}
end

get '/courses/:course/guides' do
  protect!
  Classroom::Collection::Guides.for(course).all.as_json
end

get '/courses/:course/guides/:organization/:repository' do
  protect!
  Classroom::Collection::GuideStudentsProgress.for(course).where('guide.slug' => repo_slug).as_json
end

get '/courses/:course/guides/:organization/:repository/:student_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .where(exercise_student_progress_query).as_json
end

get '/courses/:course/progress' do
  protect!
  Classroom::Collection::ExerciseStudentProgress.for(course).all.as_json
end

get '/courses/:course/guides/:organization/:repository/:student_id/:exercise_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .find_by(exercise_student_progress_query.merge('exercise.id' => exercise_id)).as_json
end

post '/courses/:course/comments' do
  protect!
  Classroom::Comments.for(course, json_body)
  Mumukit::Nuntius::Publisher.publish_comments tenantized_json_body.except(:social_id)
  {status: :created}
end

post '/courses/:course/followers' do
  protect!
  json_body['course'] = course_slug
  Classroom::Collection::Followers.for(course).add_follower json_body
  {status: :created}
end

get '/courses/:course/followers/:email' do
  by_permissions :followers do |grants|
    Classroom::Collection::Followers.for(course).where(email: params[:email], course: {'$regex' => grants}).as_json
  end
end

delete '/courses/:course/followers/:email/:social_id' do
  protect!
  Classroom::Collection::Followers.for(course).remove_follower 'course' => course_slug, 'email' => params[:email], 'social_id' => params[:social_id]
  {status: :created}
end

get '/courses/:course/exams' do
  protect!
  Classroom::Collection::Exams.for(course).all.as_json
end

post '/courses/:course/exams' do
  protect!
  exam_id = Classroom::Collection::Exams.for(course).insert! json_body.wrap_json
  Mumukit::Nuntius::Publisher.publish_exams(tenantized_json_body.merge exam_id)
  {status: :created}.merge(exam_id)
end

put '/courses/:course/exams/:exam' do
  protect!
  exam_id = Classroom::Collection::Exams.for(course).update! params[:exam], json_body
  Mumukit::Nuntius::Publisher.publish_exams(tenantized_json_body.merge exam_id)
  {status: :updated}.merge(exam_id)
end

get '/courses/:course/exams/:exam_id' do
  protect!
  Classroom::Collection::Exams.for(course).find(params[:exam_id]).as_json
end

get '/organization' do
  organization_json
end

get '/ping' do
  {message: 'pong!'}
end
