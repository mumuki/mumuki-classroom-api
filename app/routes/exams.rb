helpers do
  def create_exam
    exam_id = Classroom::Collection::Exams.for(organization, course).insert! json_body
    notify_upsert_exam(exam_id)
    {status: :created}.merge(exam_id)
  end
end

get '/courses/:course/exams' do
  authorize! :teacher
  Classroom::Collection::Exams.for(organization, course).all.as_json
end

get '/api/courses/:course/exams' do
  authorize! :teacher
  Classroom::Collection::Exams.for(organization, course).all.as_json
end

post '/courses/:course/exams' do
  authorize! :teacher
  create_exam
end

post '/api/courses/:course/exams' do
  authorize! :teacher
  create_exam
end

put '/courses/:course/exams/:exam' do
  authorize! :teacher
  exam_id = Classroom::Collection::Exams.for(organization, course).update! params[:exam], json_body
  notify_upsert_exam(exam_id)
  {status: :updated}.merge(exam_id)
end

post '/api/courses/:course/exams/:exam/students/:uid' do
  authorize! :teacher
  exam_id = Classroom::Collection::Exams.for(organization, course).add_student! params[:exam], params[:uid]
  @json_body = Classroom::Collection::Exams.for(organization, course).find_by(exam_id).as_json
  notify_upsert_exam(exam_id)
  {status: :updated}.merge(exam_id)
end

get '/courses/:course/exams/:exam_id' do
  authorize! :teacher
  Classroom::Collection::Exams.for(organization, course).find(params[:exam_id]).as_json
end
