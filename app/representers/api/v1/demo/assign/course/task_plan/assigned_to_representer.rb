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
           getter: ->(user_options:, decorator:, **) do
             DateTimeUtilities.relativize(
               opens_at, task_plan.owner.starts_at, user_options[:starts_at]
             )
           end,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           getter: ->(user_options:, decorator:, **) do
             DateTimeUtilities.relativize(
               due_at, task_plan.owner.starts_at, user_options[:starts_at]
             )
           end,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
