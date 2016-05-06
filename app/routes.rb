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
    { 'guide.slug' => repo_slug, 'student.social_id' => student_id }
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

error Classroom::StudentExistsError do
  halt 400
end

error Classroom::StudentNotExistsError do
  halt 400
end

get '/courses' do
  by_permissions :courses do | grants |
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
  Classroom::Collection::Guides.for(course).all.as_json
end

post '/courses/:course/students' do
  social_id = token.jwt['sub']

  Classroom::Collection::Courses.ensure_exist! course_slug
  Classroom::Collection::Students.for(course).ensure_new! social_id

  json = {
    student: {
      first_name: json_body['first_name'],
      last_name: json_body['last_name'],
      image_url: json_body['image_url'],
      social_id: social_id,
      email: json_body['email']
    },
    course: {
      slug: course_slug
    }
  }

  Classroom::Collection::Students.for(course).insert!(json.wrap_json)

  Mumukit::Auth::User.new(token.jwt['sub']).update_permissions('atheneum', "#{tenant}/*")

  {status: :created}
end

get '/guide_progress/:course/:organization/:repository/:student_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .where(exercise_student_progress_query).as_json
end

get '/guide_progress/:course/:organization/:repository/:student_id/:exercise_id' do
  Classroom::Collection::ExerciseStudentProgress
    .for(course)
    .find_by(exercise_student_progress_query.merge('exercise.id' => exercise_id)).as_json
end

get '/guide_progress/:course/:organization/:repository' do
  protect!
  Classroom::Collection::GuideStudentsProgress.for(course).where('guide.slug' => repo_slug).as_json
end

get '/students/:course' do
  protect!
  Classroom::Collection::Students.for(course).all.as_json
end

post '/comment/:course' do
  protect!
  Classroom::Collection::Comments.for(course).insert!(json_body.wrap_json)
  Mumukit::Nuntius::Publisher.publish_comments json_body.merge(tenant: tenant)
  { status: :created }
end

get '/comments/:course/:exercise_id' do
  protect!
  Classroom::Collection::Comments.for(course).where(exercise_id: exercise_id).as_json
end

get '/followers/:course/:email' do
  by_permissions :followers do | grants |
    Classroom::Collection::Followers.for(course).where(email: params[:email], course: { '$regex' => grants }).as_json
  end
end

post '/follower/:course' do
  protect!
  json_body['course'] = course_slug
  Classroom::Collection::Followers.for(course).add_follower json_body
  {status: :created}
end

delete '/follower/:course/:email/:social_id' do
  protect!
  Classroom::Collection::Followers.for(course).remove_follower 'course' => course_slug, 'email' => params[:email], 'social_id' => params[:social_id]
  {status: :created}
end

get '/ping' do
  {message: 'pong!'}
end
