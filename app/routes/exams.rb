get '/courses/:course/exams' do
  protect! :teacher
  Classroom::Collection::Exams.for(course).all.as_json
end

get '/api/courses/:course/exams' do
  protect! :teacher, :auth
  Classroom::Collection::Exams.for(course).all.as_json
end

def create_exam
  exam_id = Classroom::Collection::Exams.for(course).insert! json_body.wrap_json
  notify_upsert_exam(exam_id)
  {status: :created}.merge(exam_id)
end

post '/courses/:course/exams' do
  protect! :teacher
  create_exam
end

post '/api/courses/:course/exams' do
  protect! :teacher, :auth
  create_exam
end

put '/courses/:course/exams/:exam' do
  protect! :teacher
  exam_id = Classroom::Collection::Exams.for(course).update! params[:exam], json_body
  notify_upsert_exam(exam_id)
  {status: :updated}.merge(exam_id)
end

post '/api/courses/:course/exams/:exam/students/:uid' do
  protect! :teacher, :auth
  exam_id = Classroom::Collection::Exams.for(course).add_student! params[:exam], params[:uid]
  @json_body = Classroom::Collection::Exams.for(course).find_by(exam_id).as_json
  notify_upsert_exam(exam_id)
  {status: :updated}.merge(exam_id)
end

get '/courses/:course/exams/:exam_id' do
  protect! :teacher
  Classroom::Collection::Exams.for(course).find(params[:exam_id]).as_json
end
