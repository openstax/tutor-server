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

    [:recorded_at,
     :queued_at,
     :started_at,
     :succeeded_at,
     :failed_at,
     :killed_at,
     :kill_requested_at,
     ].each do |timestamp|
        property timestamp,
                 type: String,
                 readable: true,
                 writeable: false,
                 getter: ->(*) { DateTimeUtilities.to_api_s(send(timestamp)) },
                 schema_info: {
                    required: false,
                    description: "See http://github.com/openstax/jobba for a description of timestamps"
                 }
    end



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
