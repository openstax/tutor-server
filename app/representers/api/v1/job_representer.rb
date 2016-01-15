module Api::V1
  class JobRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :state,
             as: :status,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :progress,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { data['url'] },
             schema_info: { required: false }

    collection :errors,
               extend: Api::V1::ErrorRepresenter,
               readable: true,
               writeable: false,
               schema_info: { required: false }

  end
end
