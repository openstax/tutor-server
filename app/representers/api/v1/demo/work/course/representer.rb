class Api::V1::Demo::Work::Course::Representer < Api::V1::Demo::CourseRepresenter
  collection :task_plans,
             extend: Api::V1::Demo::Work::Course::TaskPlan::Representer,
             class: Demo::Mash,
             getter: ->(*) { Tasks::Models::TaskPlan.where(owner: self).preload(:tasking_plans) },
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
