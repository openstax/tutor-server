class Api::V1::Demo::Work::Course::TaskPlan::Representer < Api::V1::Demo::TaskPlanRepresenter
  collection :tasks,
             extend: Api::V1::Demo::Work::Course::TaskPlan::TaskRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
