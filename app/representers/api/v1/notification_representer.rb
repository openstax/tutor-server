module Api::V1
  class NotificationRepresenter < Roar::Decorator

    include Roar::JSON

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :message,
             type: String,
             readable: true,
             writeable: false

    property :type,
             type: String,
             readable: true,
             writeable: false

  end
end
