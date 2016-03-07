class Api::V1::NotificationsController < Api::V1::ApiController

  api :GET, '/notifications', 'Request current system notifications'
  description <<-EOS
    #{json_schema(Api::V1::NotificationRepresenter, include: :readable)}
  EOS

  def index
    # NO SECURITY!  Should it at least check if the user is logged in?
    render json: Settings::Notifications.raw
  end

end
