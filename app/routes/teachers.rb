Mumukit::Platform.map_organization_routes!(self) do
  get '/courses/:course/teachers' do
    authorize! :teacher
    {teachers: Teacher.where(with_organization_and_course).as_json}
  end

  post '/courses/:course/teachers' do
    authorize! :headmaster
    normalize_course_member!
    ensure_teacher_not_exists!

    teacher_json = json_body

    uid = teacher_json[:uid]

    Teacher.create!(with_organization_and_course teacher_json)

    user = User.where(uid: uid).first_or_initialize(teacher_json.except(:personal_id))
    user.add_permission!(:teacher, course_slug)
    user.save!

    notify_user!(user, json_body)
  end
end
