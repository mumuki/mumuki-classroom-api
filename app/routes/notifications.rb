get '/notifications' do
  authorize! :teacher
  Notification.unread(organization, current_user.permissions)
end
