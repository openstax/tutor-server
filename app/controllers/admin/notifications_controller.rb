class Admin::NotificationsController < Admin::BaseController

  def index
  end

  def create
    Settings::Notifications.add( params['new_message'] )
    redirect_to :admin_notifications
  end

  def destroy
    Settings::Notifications.remove( params['id'] )
    redirect_to :admin_notifications
  end

end
