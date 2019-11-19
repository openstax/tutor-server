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
             user_options[:starts_at] ?
               decorator.relativize(opens_at, task_plan, user_options[:starts_at]) :
               opens_at.iso8601
           end,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           getter: ->(user_options:, decorator:, **) do
             user_options[:starts_at] ?
               decorator.relativize(due_at, task_plan, user_options[:starts_at]) : due_at.iso8601
           end,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  def relativize(time, task_plan, starts_at)
    time_delta = (time - task_plan.owner.starts_at) + (starts_at - Time.current)

    "<%= Time.current #{time_delta >= 0 ? '+' : '-'} #{time_delta.abs/1.day}.days %>"
  end
end
