module Api::V1::PerformanceReport::Student::Data
  class HeadingsRepresenter < Roar::Decorator
    include Roar::JSON

    property :title,
             type: String,
             readable: true,
             writeable: false

    property :plan_id,
             type: String,
             readable: true,
             writeable: false

    property :type,
             type: String,
             readable: true,
             writeable: false

    property :due_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) }

    property :average_score,
             type: Float,
             readable: true,
             writeable: false

    property :completion_rate,
             type: Float,
             readable: true,
             writeable: false
  end
end
