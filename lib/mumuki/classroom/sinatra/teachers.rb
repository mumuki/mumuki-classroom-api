Mumukit::Platform.map_organization_routes!(self) do
  get '/courses/:course/teachers' do
    authorize! :teacher
    {teachers: Mumuki::Classroom::Teacher.where(with_organization_and_course).as_json}
  end

  post '/courses/:course/teachers' do
    authorize! :headmaster
    json = with_organization_and_course teacher: json_body.merge(uid: json_body[:email])
    uid = json[:teacher][:uid]

    Mumuki::Classroom::Teacher.create!(with_organization_and_course json[:teacher])

    perm = User.where(uid: uid).first_or_create!(json[:teacher].except(:first_name, :last_name, :personal_id)).permissions
    perm.add_permission!(:teacher, course_slug)
    User.upsert_permissions! uid, perm

    Mumukit::Nuntius.notify_event! 'UserChanged', user: json[:teacher].except(:personal_id).merge(permissions: perm)
  end
end
