module Api::V1::Courses::Cc::Student

  class ChapterRepresenter < ::Roar::Decorator

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

    property :book_location,
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    collection :pages,
               readable: true,
               writeable: false,
               extend: Api::V1::Courses::Cc::Student::PageRepresenter,
               schema_info: {
                 required: true
               }

  end

end
