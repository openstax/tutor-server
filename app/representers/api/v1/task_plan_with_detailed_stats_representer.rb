module Api::V1
  class TaskPlanWithDetailedStatsRepresenter < TaskPlanWithStatsRepresenter

    collection :stats,
               decorator: Api::V1::Tasks::Stats::StatRepresenter,
               getter: ->(args) { CalculateTaskStats[tasks: tasks, details: true] },
               readable: true,
               writable: false

  end
end
