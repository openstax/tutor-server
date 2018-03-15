module Api::V1
  class UpdatesRepresenter < Roar::Decorator

    include Roar::JSON

    collection :notifications, extend: NotificationRepresenter

    property :tutor_js_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(**) { Rails.application.secrets.js_url }

    property :payments, writeable: false, readable: true, getter: ->(*) {
      {
        is_enabled: Settings::Payments.payments_enabled
      }
    }

  end

end
