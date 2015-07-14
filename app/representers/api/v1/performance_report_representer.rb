module Api::V1
  class PerformanceReportRepresenter < Roar::Decorator

    include Representable::JSON::Collection

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

      property :exercise_count,
               type: Integer,
               readable: true

      property :correct_exercise_count,
               type: Integer,
               readable: true

      property :recovered_exercise_count,
               type: Integer,
               readable: true
    end

    class Students < Roar::Decorator

      include Roar::JSON

      property :name,
               type: String,
               readable: true

      property :role,
               type: String,
               readable: true

      collection :data,
                 readable: true,
                 decorator: StudentData

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

      property :average,
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
