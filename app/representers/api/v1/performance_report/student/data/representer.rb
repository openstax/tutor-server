module Api::V1::PerformanceReport::Student::Data
  class Representer < Roar::Decorator
    include Roar::JSON

    property :type,
             type: String,
             readable: true

    property :id,
             type: String,
             readable: true

    property :status,
             type: String,
             readable: true

    property :step_count,
             type: Integer,
             readable: true

    property :completed_step_count,
             type: Integer,
             readable: true

    property :completed_on_time_step_count,
             type: Integer,
             readable: true

    property :completed_accepted_late_step_count,
             type: Integer,
             readable: true

    property :actual_and_placeholder_exercise_count,
             as: :exercise_count,
             type: Integer,
             readable: true

    property :completed_exercise_count,
             type: Integer,
             readable: true

    property :completed_on_time_exercise_count,
             type: Integer,
             readable: true

    property :completed_accepted_late_exercise_count,
             type: Integer,
             readable: true

    property :correct_exercise_count,
             type: Integer,
             readable: true

    property :correct_on_time_exercise_count,
             type: Integer,
             readable: true

    property :correct_accepted_late_exercise_count,
             type: Integer,
             readable: true

    property :score,
             type: Float,
             readable: true

    property :recovered_exercise_count,
             type: Integer,
             readable: true

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

    property :accepted_late_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(accepted_late_at) },
             schema: {
               description: "Will only be set when late work has been accepted; " +
                            "will go away if accepted late work is later rejected."
             }

    property :is_included_in_averages,
             readable: true,
             writeable: false
  end
end
