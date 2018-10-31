Mumukit::Platform.map_organization_routes!(self) do
  get '/notifications/unread' do
    authorize! :teacher
    { notifications: Notification.unread(organization, current_user.permissions) }
  end

  get '/notifications' do
    authorize! :teacher
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    {total: Notification.count,
     page: page,
     notifications: Notification.page(organization, current_user.permissions, page, per_page)}
  end

  put '/notifications/:notificationId/read' do
    authorize! :teacher
    Notification.find(params[:notificationId]).read!
    {status: :updated}
  end

  put '/notifications/:notificationId/unread' do
    authorize! :teacher
    Notification.find(params[:notificationId]).unread!
    {status: :updated}
  end
end
