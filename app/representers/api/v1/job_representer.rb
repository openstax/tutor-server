module Api::V1
  class JobRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :status,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :progress,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :url, if: ->(*) { respond_to?(:url) },
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: false }

    collection :errors,
               extend: Api::V1::ErrorRepresenter,
               readable: true,
               writeable: false,
               schema_info: { required: false }

  end
end
