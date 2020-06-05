class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def exam_id
      params[:exam_id]
    end

    def exam_query
      {classroom_id: exam_id}
    end

    def exam_body
      Exam.from_classroom_json with_current_organization_and_course(json_body)
    end

  end

  Mumukit::Platform.map_organization_routes!(self) do
    get '/courses/:course/exams/:exam_id' do
      authorize! :teacher
      exam = Exam.find_by!(exam_query)
      exam.as_classroom_json
    end

    put '/courses/:course/exams/:exam_id' do
      authorize! :teacher
      exam = Exam.find_by!(exam_query)
      exam.update_attributes! exam_body
      {status: :updated}.merge(eid: exam_id)
    end

    ['/api', ''].each do |route_prefix|
      get "#{route_prefix}/courses/:course/exams" do
        authorize! :teacher
        {exams: Exam.where(with_current_organization_and_course).map(&:as_classroom_json)}
      end

      post "#{route_prefix}/courses/:course/exams" do
        authorize! :teacher
        exam = Exam.create! exam_body
        {status: :created}.merge(eid: exam.classroom_id)
      end

      post "#{route_prefix}/courses/:course/exams/:exam_id/students/:uid" do
        authorize! :teacher
        Exam.upsert_students!(eid: exam_id, added: [uid])
        {status: :updated}.merge(eid: exam_id)
      end

      delete "#{route_prefix}/courses/:course/exams/:exam_id/students/:uid" do
        authorize! :teacher
        Exam.upsert_students!(eid: exam_id, deleted: [uid])
        {status: :updated}.merge(eid: exam_id)
      end
    end

  end
end
