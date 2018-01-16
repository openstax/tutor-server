module Api::V1::PerformanceReport::Student
  class Representer < Roar::Decorator
    include Roar::JSON

    property :name,
             type: String,
             readable: true,
             writeable: false

    property :first_name,
             type: String,
             readable: true,
             writeable: false

    property :last_name,
             type: String,
             readable: true,
             writeable: false

    property :role,
             type: String,
             readable: true,
             writeable: false

    property :student_identifier,
             type: String,
             readable: true,
             writeable: false

    property :course_average,
             type: Float,
             readable: true,
             writeable: false

    property :homework_score,
             type: Float,
             readable: true,
             writeable: false

    property :homework_progress,
             type: Float,
             readable: true,
             writeable: false

    property :reading_score,
             type: Float,
             readable: true,
             writeable: false

    property :reading_progress,
             type: Float,
             readable: true,
             writeable: false

    property :is_dropped,
             readable: true,
             writeable: false

    collection :data,
               readable: true,
               writeable: false,
               extend: ->(input:, **) do
      input.nil? ? ::Api::V1::PerformanceReport::Student::Data::NullRepresenter :
                   ::Api::V1::PerformanceReport::Student::Data::Representer
    end
  end
end
