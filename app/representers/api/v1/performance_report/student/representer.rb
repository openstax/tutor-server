module Api::V1::PerformanceReport::Student
  class Representer < Roar::Decorator
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
               extend: ->(input:, **) { input.nil? ? Data::NullRepresenter : Data::Representer }
  end
end
