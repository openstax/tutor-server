class Api::V1::NotificationsController < Api::V1::ApiController

  api :GET, '/notifications', 'Request current system notifications'
  description <<-EOS
    #{json_schema(Api::V1::NotificationRepresenter, include: :readable)}
  EOS

  def index
    # Note: this endpoint is unsecure by design.
    # General notifications are intended to be viewable by anyone
    is_instructor = current_human_user.to_model.roles.any?(&:teacher?)

    notifications = get_notifications(:general)
    notifications = get_notifications(:instructor) + notifications if is_instructor

    render json: notifications
  end

  protected

  def get_notifications(type)
    Settings::Notifications.messages(type).map do |id, message|
      { type: type.to_s, id: id, message: message }
    end
  end

end
