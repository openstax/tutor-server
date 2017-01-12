module Api::V1

  class LogEntriesRepresenter < Roar::Decorator

    include Roar::JSON

    collection :entries,
               instance: ->(*) { ::Hashie::Mash.new },
               extend: LogEntryRepresenter,
               readable: true,
               writeable: true

    property :level,
             type: String,
             readable: false,
             writeable: true

    property :message,
             type: String,
             readable: false,
             writeable: true
  end
end
