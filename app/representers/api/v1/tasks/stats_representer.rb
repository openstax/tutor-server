module Api::V1
  module Tasks
    class StatsRepresenter < Roar::Decorator
      include Roar::JSON
      include Representable::Coercion

      property :period_id,
               type: String,
               readable: true,
               writeable: false

      property :name,
               type: String,
               readable: true,
               writeable: false

      property :total_count,
               type: Integer,
               readable: true,
               writeable: false

      property :complete_count,
               type: Integer,
               readable: true,
               writeable: false

      property :partially_complete_count,
               type: Integer,
               readable: true,
               writeable: false
    end
  end
end
