class Api::V1::Demo::Assign::Course::TaskPlan::AssignedToRepresenter < Api::V1::Demo::BaseRepresenter
  property :period,
           extend: Api::V1::Demo::PeriodRepresenter,
           class: Demo::Mash,
           getter: ->(*) { target },
           readable: true,
           writeable: true

  property :opens_at,
           type: String,
           getter: ->(*) { DateTimeUtilities.to_api_s opens_at },
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           getter: ->(*) { DateTimeUtilities.to_api_s due_at },
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :closes_at,
           type: String,
           getter: ->(*) { DateTimeUtilities.to_api_s due_at },
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
