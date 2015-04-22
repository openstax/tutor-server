module Api::V1
  class TaskPlanWithDetailedStatsRepresenter < TaskPlanRepresenter

    property :stats,
             extend: Tasks::Stats::TaskPlanRepresenter,
             getter: ->(args) {
               CalculateTaskPlanStats[plan: self, details: true]
             },
             if: ->(args) { !published_at.nil? },
             readable: true,
             writable: false

  end
end
