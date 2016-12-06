class Admin::NotificationsController < Admin::BaseController

  def index
  end

  def create
    redirect_to :admin_notifications, error: "Invalid notification type \"#{params['type']}\"" \
      unless Settings::Notifications.valid_type?(params['type'])

    Settings::Notifications.add(params['type'], params['message'])

    redirect_to :admin_notifications, notice: "#{params['type'].humanize} notification created"
  end

  def destroy
    Settings::Notifications.remove(params['type'], params['id'])

    redirect_to :admin_notifications, notice: "#{params['type'].humanize} notification deleted"
  end

end
