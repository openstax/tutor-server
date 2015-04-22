module Api::V1
  class TaskPlanWithDetailedStatsRepresenter < TaskPlanRepresenter

    property :stats,
             extend: Tasks::Stats::TaskPlanRepresenter,
             getter: ->(args) {
               CalculateTaskPlanStats[plan: self, details: true]
             },
             readable: true,
             writable: false

  end
end
