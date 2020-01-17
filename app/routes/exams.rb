helpers do
  def exam_id
    params[:exam_id]
  end

  def exam_query
    with_organization_and_course(eid: exam_id)
  end
end

Mumukit::Platform.map_organization_routes!(self) do
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
    {status: :created}.merge(eid: exam.eid)
  end

  post '/api/courses/:course/exams' do
    authorize! :teacher
    exam = Exam.create! with_organization_and_course(json_body)
    exam.notify!
    {status: :created}.merge(eid: exam.eid)
  end

  get '/courses/:course/exams/:exam_id' do
    authorize! :teacher
    Exam.find_by!(exam_query).as_json
  end

  put '/courses/:course/exams/:exam_id' do
    authorize! :teacher
    exam = Exam.find_by!(exam_query)
    exam.update_attributes! json_body
    exam.notify!
    {status: :updated}.merge(eid: exam_id)
  end

  ['/api', ''].each do |route_prefix|
    post "#{route_prefix}/courses/:course/exams/:exam_id/students/:uid" do
      authorize! :teacher
      exam = Exam.find_by!(exam_query)
      exam.add_student! uid
      notify_exam_students! exam, added: [uid]
      {status: :updated}.merge(eid: exam_id)
    end

    delete "#{route_prefix}/courses/:course/exams/:exam_id/students/:uid" do
      authorize! :teacher
      exam = Exam.find_by!(exam_query)
      exam.remove_student! uid
      notify_exam_students! exam, deleted: [uid]
      {status: :updated}.merge(eid: exam_id)
    end
  end
end
