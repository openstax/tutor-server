module Api::V1
  class UpdatesRepresenter < Roar::Decorator

    include Roar::JSON

    collection :notifications, extend: NotificationRepresenter

    property :payments, writeable: false, readable: true, getter: ->(*) {
      {
        is_enabled: Settings::Payments.payments_enabled
      }
    }

  end

end
