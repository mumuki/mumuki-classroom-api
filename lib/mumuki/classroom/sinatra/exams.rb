class Mumuki::Classroom::App < Sinatra::Application
  helpers do
    def exam_id
      params[:exam_id]
    end

    def exam_query
      {classroom_id: exam_id}
    end

    def exam_from_classroom_json(json)
      exam = json.with_indifferent_access
      Exam.adapt_json_values exam
      Exam.whitelist_attributes exam
    end

    def exam_body
      exam_from_classroom_json with_current_organization_and_course(json_body)
    end

    def exam_as_json_response(exam)
      exam.as_json
          .merge(eid: exam.classroom_id, name: exam.guide.name, language: exam.guide.language.name,
                 slug: exam.guide.slug, uids: exam.users.map(&:uid), course: exam.course.slug,
                 organization: exam.organization.name, passing_criterion: exam.passing_criterion.as_json)
          .except(:classroom_id, :guide_id, :course_id, :organization_id,
                  :passing_criterion_type, :passing_criterion_value)
    end
  end

  Mumukit::Platform.map_organization_routes!(self) do
    get '/courses/:course/exams/:exam_id' do
      authorize! :teacher
      exam = Exam.find_by!(exam_query)
      exam_as_json_response exam
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
        {exams: Exam.where(with_current_organization_and_course).map { |it| exam_as_json_response(it) }}
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
