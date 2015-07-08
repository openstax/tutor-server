module Api::V1
  class CourseGuideRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::JSON::Collection

    property :title,
             type: String,
             readable: true,
             writeable: false

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
