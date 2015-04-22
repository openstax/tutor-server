module Api::V1
  class TaskPlanWithStatsRepresenter < Roar::Decorator

    include Roar::JSON

    property :id,
             type: Integer,
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

    property :opens_at,
             type: String,
             readable: true,
             writeable: true

    property :published_at,
             type: String,
             readable: true,
             writeable: true

    property :due_at,
             type: String,
             readable: true,
             writeable: true

    property :settings,
             type: Object,
             readable: true,
             writeable: true

    property :stats,
             extend: Tasks::Stats::TaskPlanRepresenter,
             getter: ->(args){ CalculateTaskPlanStats[plan: self] },
             if: ->(args) { !published_at.nil? },
             readable: true,
             writable: false

  end
end
