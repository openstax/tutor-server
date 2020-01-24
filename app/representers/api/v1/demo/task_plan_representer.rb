class Api::V1::Demo::TaskPlanRepresenter < Api::V1::Demo::BaseRepresenter
  # One of either id or title is required
  property :id,
           type: String,
           readable: false,
           writeable: true

  property :title,
           type: String,
           readable: true,
           writeable: true
end
