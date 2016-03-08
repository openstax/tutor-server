class Api::V1::NotificationsController < Api::V1::ApiController

  api :GET, '/notifications', 'Request current system notifications'
  description <<-EOS
    #{json_schema(Api::V1::NotificationRepresenter, include: :readable)}
  EOS

  def index
    # Note: this endpoint is unsecured by design.
    # Notifications are intended to be viewable by anyone
    render json: Settings::Notifications.raw
  end

end
