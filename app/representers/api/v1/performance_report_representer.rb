module Api::V1
  class PerformanceReportRepresenter < Roar::Decorator

    include Representable::JSON::Collection

    class Null < Roar::Decorator

      include Roar::JSON

      def to_hash(*args)
        nil
      end

      def to_json(*args)
        'null'
      end

    end

    class StudentData < Roar::Decorator

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

    class Students < Roar::Decorator

      include Roar::JSON

      property :name,
               type: String,
               readable: true

      property :first_name,
               type: String,
               readable: true

      property :last_name,
               type: String,
               readable: true

      property :role,
               type: String,
               readable: true

      property :student_identifier,
               type: String,
               readable: true

      property :average_score,
               type: Float,
               readable: true

      property :is_dropped,
               readable: true,
               writeable: false

      collection :data,
                 readable: true,
                 extend: ->(input:, **) { input.nil? ? Null : StudentData }

    end

    class DataHeadings < Roar::Decorator

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

    class ReportPerPeriod < Roar::Decorator

      include Roar::JSON

      property :period_id,
               type: String,
               readable: true,
               getter: ->(*) { period.id.to_s }

      property :overall_average_score,
               type: Float,
               readable: true

      collection :data_headings,
                 readable: true,
                 extend: DataHeadings

      collection :students,
                 readable: true,
                 extend: Students
    end

    items extend: ReportPerPeriod

  end

end
