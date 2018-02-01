module Api::V1::PerformanceReport
  class PeriodRepresenter < Roar::Decorator
    include Roar::JSON

    property :period_id,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { period.id.to_s }

    property :overall_course_average,
             type: Float,
             readable: true,
             writeable: false

    property :overall_homework_score,
             type: Float,
             readable: true,
             writeable: false

    property :overall_homework_progress,
             type: Float,
             readable: true,
             writeable: false

    property :overall_reading_score,
             type: Float,
             readable: true,
             writeable: false

    property :overall_reading_progress,
             type: Float,
             readable: true,
             writeable: false

    collection :data_headings,
               readable: true,
               writeable: false,
               extend: ::Api::V1::PerformanceReport::Student::Data::HeadingRepresenter

    collection :students,
               readable: true,
               writeable: false,
               extend: ::Api::V1::PerformanceReport::Student::Representer
  end
end
