module Api::V1
  class CourseGuideChildRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    collection :book_location,
               as: :chapter_section,
               readable: true,
               writeable: false

    property :student_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :questions_answered_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :practice_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :clue,
             extend: ClueRepresenter,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    collection :page_ids,
               readable: true,
               writeable: false,
               getter: ->(*) { page_ids && page_ids.map(&:to_s) },
               schema_info: {
                 required: true,
                 description: "Page IDs as strings ['1', '2', ...]"
               }

    collection :children,
               readable: true,
               writeable: false,
               extend: CourseGuideChildRepresenter
  end
end
