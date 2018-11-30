Mumukit::Platform.map_organization_routes!(self) do
  get '/notifications/unread' do
    authorize! :teacher
    { notifications: Mumuki::Classroom::Notification.unread(organization, current_user.permissions) }
  end

  get '/notifications' do
    authorize! :teacher
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    {total: Mumuki::Classroom::Notification.count,
     page: page,
     notifications: Mumuki::Classroom::Notification.page(organization, current_user.permissions, page, per_page)}
  end

  put '/notifications/:notificationId/read' do
    authorize! :teacher
    Mumuki::Classroom::Notification.find(params[:notificationId]).read!
    {status: :updated}
  end

  put '/notifications/:notificationId/unread' do
    authorize! :teacher
    Mumuki::Classroom::Notification.find(params[:notificationId]).unread!
    {status: :updated}
  end
end
