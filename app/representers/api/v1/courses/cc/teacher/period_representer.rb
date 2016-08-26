module Api::V1::Courses::Cc::Teacher

  class PeriodRepresenter < ::Roar::Decorator

    include ::Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    property :name,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true
             }

    collection :chapters,
               readable: true,
               writeable: false,
               extend: Api::V1::Courses::Cc::Teacher::ChapterRepresenter,
               schema_info: {
                 required: true
               }

  end

end
