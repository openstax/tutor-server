class Api::V1::Demo::Assign::Course::Representer < Api::V1::Demo::CourseRepresenter
  collection :task_plans,
             extend: Api::V1::Demo::Assign::Course::TaskPlan::Representer,
             class: Demo::Mash,
             getter: ->(*) { Tasks::Models::TaskPlan.where(course: self).preload(:tasking_plans) },
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
