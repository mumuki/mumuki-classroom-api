get '/courses/:course/students' do
  authorize! :teacher
  {students: Student.where(with_organization_and_course)}
end

get '/api/courses/:course/students' do
  authorize! :teacher
  {students: Student.where(with_organization_and_course)}
end

get '/api/courses/:course/students/:uid' do
  authorize! :teacher
  {guide_students_progress: GuideProgress.where(with_organization_and_course 'student.uid': uid).as_json}
end

post '/courses/:course/students/:uid' do
  authorize! :janitor
  Mumukit::Nuntius.notify! 'resubmissions', uid: uid, tenant: tenant
  {status: :created}
end

post '/courses/:course/students/:uid/detach' do
  authorize! :janitor
  Student.find_by!(with_organization_and_course uid: uid).detach!
  update_and_notify_student_metadata(uid, 'remove')
  {status: :updated}
end

post '/courses/:course/students/:uid/attach' do
  authorize! :janitor
  Student.find_by!(with_organization_and_course uid: uid).attach!
  update_and_notify_student_metadata(uid, 'add')
  {status: :updated}
end

get '/courses/:course/student/:uid' do
  authorize! :teacher

  Student.find_by!(with_organization_and_course uid: uid).as_json
end
