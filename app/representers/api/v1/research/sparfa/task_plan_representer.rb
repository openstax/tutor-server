class Api::V1::Research::Sparfa::TaskPlanRepresenter < Api::V1::Research::TaskPlanRepresenter
  collection :students,
             extend: Api::V1::Research::Sparfa::StudentTaskRepresenter,
             readable: true,
             writeable: false,
             schema_info: { required: true }
end
