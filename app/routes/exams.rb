helpers do
  def exam_id
    params[:exam_id]
  end

  def exam_query
    with_organization_and_course(id: exam_id)
  end
end

get '/courses/:course/exams' do
  authorize! :teacher
  {exams: Exam.where(with_organization_and_course).as_json}
end

get '/api/courses/:course/exams' do
  authorize! :teacher
  {exams: Exam.where(with_organization_and_course).as_json}
end

post '/courses/:course/exams' do
  authorize! :teacher
  exam = Exam.create! with_organization_and_course(json_body)
  exam.notify!
  {status: :created}.merge(id: exam.id)
end

post '/api/courses/:course/exams' do
  authorize! :teacher
  exam = Exam.create! with_organization_and_course(json_body)
  exam.notify!
  {status: :created}.merge(id: exam.id)
end

put '/courses/:course/exams/:exam_id' do
  authorize! :teacher
  exam = Exam.find_by!(exam_query)
  exam.update_attributes! json_body
  exam.notify!
  {status: :updated}.merge(id: exam_id)
end

post '/api/courses/:course/exams/:exam_id/students/:uid' do
  authorize! :teacher
  exam = Exam.find_by!(exam_query)
  exam.add_student! params[:uid]
  exam.notify!
  {status: :updated}.merge(id: exam_id)
end

get '/courses/:course/exams/:exam_id' do
  authorize! :teacher
  Exam.find_by!(exam_query).as_json
end
