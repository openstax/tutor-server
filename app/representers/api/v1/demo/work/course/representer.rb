class Api::V1::Demo::Work::Course::Representer < Api::V1::Demo::CourseRepresenter
  collection :task_plans,
             extend: Api::V1::Demo::Work::Course::TaskPlan::Representer,
             class: Demo::Mash,
             getter: ->(*) do
               Tasks::Models::TaskPlan.where(course: self).where.not(
                 type: 'event'
               ).preload(:tasking_plans)
             end,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
