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

    property :description,
             type: String,
             readable: true,
             writeable: true

    collection :stats,
               decorator: Api::V1::Tasks::Stats::PeriodRepresenter,
               getter: ->(args) { CalculateTaskStats[tasks: tasks] },
               readable: true,
               writable: false

  end
end
