module Api::V1::PerformanceReport
  class PeriodRepresenter < Roar::Decorator
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
               extend: Student::Data::HeadingsRepresenter

    collection :students,
               readable: true,
               extend: StudentRepresenter
  end
end
