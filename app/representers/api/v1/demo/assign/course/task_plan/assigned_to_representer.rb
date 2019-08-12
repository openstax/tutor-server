class Api::V1::Demo::Assign::Course::TaskPlan::AssignedToRepresenter < Api::V1::Demo::BaseRepresenter
  property :period,
           extend: Api::V1::Demo::PeriodRepresenter,
           class: Demo::Mash,
           readable: true,
           writeable: true

  property :opens_at,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
