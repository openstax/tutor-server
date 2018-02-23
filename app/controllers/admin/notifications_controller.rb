class Admin::NotificationsController < Admin::BaseController

  def index
  end

  def create
    type = params[:type]
    redirect_to :admin_notifications, error: "Invalid notification type \"#{type}\"" \
      unless Settings::Notifications.valid_type?(type: type)

    Settings::Notifications.add **params.slice(:type, :message, :from, :to).symbolize_keys

    redirect_to :admin_notifications, notice: "#{type.humanize} notification created"
  end

  def destroy
    Settings::Notifications.remove **params.slice(:type, :id).symbolize_keys

    redirect_to :admin_notifications, notice: "#{params[:type].humanize} notification deleted"
  end

end
