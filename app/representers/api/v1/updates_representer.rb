module Api::V1
  class UpdatesRepresenter < Roar::Decorator

    include Roar::JSON

    collection :notifications, extend: NotificationRepresenter

    property :tutor_js_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(**) { Tutor::Assets::Scripts[:tutor] }

    property :payments, writeable: false, readable: true, getter: ->(*) {
      {
        is_enabled: Settings::Payments.payments_enabled
      }
    }

    property :feature_flags, writeable: false, readable: true, getter: ->(*) { Settings.feature_flags }

  end

end
