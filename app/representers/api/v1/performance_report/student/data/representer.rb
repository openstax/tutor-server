module Api::V1::PerformanceReport::Student::Data
  class Representer < Roar::Decorator
    include Roar::JSON

    property :type,
             type: String,
             readable: true,
             writeable: false

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :status,
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

    property :actual_and_placeholder_exercise_count,
             as: :exercise_count,
             type: Integer,
             readable: true,
             writeable: false

    property :completed_exercise_count,
             type: Integer,
             readable: true,
             writeable: false

    property :correct_exercise_count,
             type: Integer,
             readable: true,
             writeable: false

    property :recovered_exercise_count,
             type: Integer,
             readable: true,
             writeable: false

    property :due_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) }

    property :last_worked_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_worked_at) }

    property :is_late_work_accepted,
             readable: true,
             writeable: false

    property :score,
             type: Float,
             readable: true,
             writeable: false

    property :progress,
             type: Float,
             readable: true,
             writeable: false

    property :is_included_in_averages,
             readable: true,
             writeable: false

    property :available_points,
             readable: true,
             writeable: false

    property :points,
             readable: true,
             writeable: false

  end
end
