module Api::V1
  class TaskPlanWithDetailedStatsRepresenter < TaskPlanWithStatsRepresenter

    property :stats,
             decorator: Api::V1::Tasks::Stats::TaskPlanRepresenter,
             getter: ->(args) {
               CalculateTaskPlanStats[plan: self, details: true]
             },
             readable: true,
             writable: false

  end
end
