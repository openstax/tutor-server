module Api::V1::PerformanceReport::Student::Data
  class Representer < Roar::Decorator
    include Roar::JSON

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :step_count,
             type: Integer,
             readable: true,
             writeable: false

    property :completed_step_count,
             type: Integer,
             readable: true,
             writeable: false

    property :due_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) }

    property :progress,
             type: Float,
             readable: true,
             writeable: false

    property :available_points,
             type: Float,
             readable: true,
             writeable: false

    property :published_points,
             type: Float,
             readable: true,
             writeable: false

    property :published_score,
             type: Float,
             readable: true,
             writeable: false

    property :is_provisional_score,
             readable: true,
             writeable: false,
             schema_info: { type: 'boolean' }

    # only used by old scores report
    property :completed_on_time_steps_count,
             type: Integer,
             readable: true,
             writeable: false
  end
end
