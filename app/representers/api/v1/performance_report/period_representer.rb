module Api::V1::PerformanceReport
  class PeriodRepresenter < Roar::Decorator
    include Roar::JSON

    property :period_id,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { period.id.to_s }

    property :overall_average_score,
             type: Float,
             readable: true,
             writeable: false

    collection :data_headings,
               readable: true,
               writeable: false,
               extend: ::Api::V1::PerformanceReport::Student::Data::HeadingsRepresenter

    collection :students,
               readable: true,
               writeable: false,
               extend: ::Api::V1::PerformanceReport::Student::Representer
  end
end
