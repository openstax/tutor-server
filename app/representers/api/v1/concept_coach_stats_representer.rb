module Api::V1
  class ConceptCoachStatsRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :title,
             type: String,
             readable: true,
             writeable: true

    collection :stats,
               decorator: Api::V1::Tasks::Stats::StatRepresenter,
               readable: true,
               writable: false

  end
end
