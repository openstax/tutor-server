module Api::V1
  class ErrorRepresenter < Roar::Decorator

    include Representable::JSON::Hash
    include Representable::Coercion

    property :is_fatal,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :code,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :message,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  end
end
