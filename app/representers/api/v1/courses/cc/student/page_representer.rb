module Api::V1::Courses::Cc::Student

  class PageRepresenter < ::Roar::Decorator

    include ::Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :uuid,
             type: String,
             readable: true,
             writeable: false

    property :version,
             type: String,
             readable: true,
             writeable: false

    property :book_location,
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :last_worked_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_worked_at) }

    collection :exercises,
               readable: true,
               writeable: false,
               extend: Api::V1::Courses::Cc::Student::ExerciseRepresenter,
               schema_info: {
                 required: true
               }

  end

end
