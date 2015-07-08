module Api::V1
  class CourseGuideChildRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    collection :chapter_section,
               readable: true,
               writeable: false

    property :questions_answered_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :current_level,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :practice_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    collection :page_ids,
               readable: true,
               writeable: false,
               getter: -> (*) { page_ids && page_ids.map(&:to_s) },
               schema_info: { items: { type: 'string' } }

    collection :children,
               readable: true,
               writeable: false,
               decorator: CourseGuideChildRepresenter
  end
end
