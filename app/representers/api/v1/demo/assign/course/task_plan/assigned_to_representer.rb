class Api::V1::Demo::Assign::Course::TaskPlan::AssignedToRepresenter < Api::V1::Demo::BaseRepresenter
  property :period,
           extend: Api::V1::Demo::PeriodRepresenter,
           class: Demo::Mash,
           getter: ->(*) { target },
           readable: true,
           writeable: true

  property :opens_at,
           type: String,
           readable: true,
           getter: ->(*) { (opens_at - task_plan.owner.starts_at) / 1.days  },
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           getter: ->(*) { (due_at - task_plan.owner.starts_at) / 1.days  },
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
