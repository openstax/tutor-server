module Api::V1::PerformanceReport::Student::Data
  class HeadingsRepresenter < Roar::Decorator
    include Roar::JSON

    property :title,
             type: String,
             readable: true

    property :plan_id,
             type: String,
             readable: true

    property :type,
             type: String,
             readable: true

    property :due_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) }

    property :average_score,
             type: Float,
             readable: true

    property :completion_rate,
             type: Float,
             readable: true
  end
end
