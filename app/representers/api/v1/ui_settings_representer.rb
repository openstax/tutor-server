module Api::V1
  class UiSettingsRepresenter < Roar::Decorator

    include Roar::JSON

    property :previous_ui_settings,
             type: Hash,
             readable: true,
             writeable: true,
             schema_info: { required: true }

    property :ui_settings,
             type: Hash,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  end
end
