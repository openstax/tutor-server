module Api::V1
  module ConceptCoach
    class StatsRepresenter < Roar::Decorator

      include Roar::JSON
      include Representable::Coercion

      property :title,
               type: String,
               readable: true,
               writeable: true

      property :type,
               type: String,
               readable: true,
               writeable: true,
               getter: ->(*) { 'concept_coach' }

      collection :stats,
                 decorator: Api::V1::ConceptCoach::PeriodStatsRepresenter,
                 readable: true,
                 writable: false

    end
  end
end
