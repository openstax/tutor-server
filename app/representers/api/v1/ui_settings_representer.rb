module Api::V1
  class UiSettingsRepresenter < Roar::Decorator

    include Roar::JSON

    property :ui_settings,
             type: Hash,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  end
end
