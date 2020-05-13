module Api::V1::PerformanceReport::Student::Data
  class HeadingRepresenter < Roar::Decorator
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

    property :available_points,
             type: Float,
             readable: true,
             writeable: false

    property :average_score,
             type: Float,
             readable: true,
             writeable: false

    property :average_progress,
             type: Float,
             readable: true,
             writeable: false
  end
end
