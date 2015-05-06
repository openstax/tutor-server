module Api::V1
  class TaskPlanWithStatsRepresenter < ::Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :type,
             type: String,
             readable: true,
             writeable: true

    property :title,
             type: String,
             readable: true,
             writeable: true

    property :stats,
             decorator: Api::V1::Tasks::Stats::TaskPlanRepresenter,
             getter: ->(args) { CalculateTaskPlanStats[plan: self] },
             readable: true,
             writable: false

  end
end
