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

      property :actual_and_placeholder_exercise_count,
               as: :exercise_count,
               type: Integer,
               readable: true

      property :completed_exercise_count,
               type: Integer,
               readable: true

      property :correct_exercise_count,
               type: Integer,
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

      collection :data,
                 readable: true,
                 decorator: ->(object, *) { object.nil? ? Null : StudentData }

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

      property :total_average,
               type: Float,
               readable: true

      property :attempted_average,
               type: Float,
               readable: true
    end

    class ReportPerPeriod < Roar::Decorator

      include Roar::JSON

      property :period_id,
               type: String,
               readable: true,
               getter: -> (*) { period.id.to_s }

      collection :data_headings,
                 readable: true,
                 decorator: DataHeadings

      collection :students,
                 readable: true,
                 decorator: Students
    end

    items extend: ReportPerPeriod

  end

end
