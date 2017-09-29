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
             getter: ->(*) { state.nil? ? Jobba::State::UNKNOWN.name : state.name },
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
             getter: ->(*) { data.try :[], 'url' }, # data is not guaranteed to be a hash
             schema_info: { required: false }

    property :data,
             type: Hash,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    collection :errors,
               extend: Api::V1::ErrorRepresenter,
               readable: true,
               writeable: false,
               schema_info: { required: false }

  end
end
