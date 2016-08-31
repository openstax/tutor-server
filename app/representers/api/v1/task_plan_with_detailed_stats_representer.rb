module Api::V1
  class TaskPlanWithDetailedStatsRepresenter < TaskPlanWithStatsRepresenter

    collection :stats,
               extend: Api::V1::Tasks::Stats::StatRepresenter,
               getter: ->(*) { CalculateTaskStats[tasks: tasks, details: true] },
               readable: true,
               writable: false

  end
end
