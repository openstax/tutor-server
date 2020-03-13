class Api::V1::TaskPlan::Stats::DetailedRepresenter < Api::V1::TaskPlan::Stats::Representer
  collection :stats,
             extend: Api::V1::Tasks::Stats::Representer,
             getter: ->(*) { CalculateTaskStats[tasks: tasks, details: true] },
             readable: true,
             writable: false
end
