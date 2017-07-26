class Api::V1::UpdatesController < Api::V1::ApiController

  api :GET, '/notifications', 'Request current system notifications'
  description <<-EOS
    #{json_schema(Api::V1::NotificationRepresenter, include: :readable)}
  EOS

  def index
    # Note: this endpoint is unsecure by design.
    # General notifications are intended to be viewable by anyone

    respond_with updates, represent_with: Api::V1::UpdatesRepresenter
  end

  protected

  def updates
    notifications = get_notifications(:general)
    notifications.concat(get_notifications(:instructor)) if current_human_user.to_model.roles.any?(&:teacher?)

    OpenStruct.new({
      notifications: notifications
    })

  end

  def get_notifications(type)
    Settings::Notifications.messages(type).map do |id, message|
      OpenStruct.new(type: type.to_s, id: id, message: message)
    end
  end

end
