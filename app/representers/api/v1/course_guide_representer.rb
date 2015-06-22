module Api::V1
  class CourseGuideRepresenter < Roar::Decorator
    include Roar::JSON

    property :title,
             type: String,
             readable: true,
             writeable: false

    collection :page_ids,
               readable: true,
               writeable: false,
               schema_info: { items: { type: 'string' } }

    collection :children,
               readable: true,
               writeable: false
  end
end
