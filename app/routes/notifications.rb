get '/notifications' do
  authorize! :teacher
  Notification.unread(organization, current_user.permissions)
end

put '/notifications/:notificationId/read' do
  authorize! :teacher
  Notification.find(params[:notificationId]).read!
  {status: :updated}
end
