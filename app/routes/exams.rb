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