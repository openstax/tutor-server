module Api::V1
  class PerformanceReportRepresenter < Roar::Decorator

    include Representable::JSON::Collection

    class StudentData < Roar::Decorator

      include Roar::JSON

      property :type,
               type: String,
               readable: true

      property :id,
               type: Integer,
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
               type: Integer,
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

      property :average,
               type: Float,
               readable: true
    end

    class ReportPerPeriod < Roar::Decorator

      include Roar::JSON

      property :period,
               readable: true,
               decorator: PeriodRepresenter

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
