module Api::V1
  class LogEntryRepresenter < Roar::Decorator

    include Roar::JSON

    property :level,
             type: String,
             readable: false,
             writeable: true,
             schema_info: { required: true }

    property :message,
             type: String,
             readable: false,
             writeable: true,
             schema_info: { required: true }
  end
end
