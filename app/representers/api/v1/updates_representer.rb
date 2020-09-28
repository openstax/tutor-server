module Api::V1
  class UpdatesRepresenter < Roar::Decorator

    include Roar::JSON

    collection :notifications, extend: NotificationRepresenter

    property :tutor_assets_hash,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(**) { OpenStax::Utilities::Assets.digest_for(:tutor) }

    property :payments, writeable: false, readable: true, getter: ->(*) {
      {
        is_enabled: Settings::Payments.payments_enabled
      }
    }

    property :feature_flags, writeable: false, readable: true, getter: ->(*) { Settings.feature_flags }

  end

end
