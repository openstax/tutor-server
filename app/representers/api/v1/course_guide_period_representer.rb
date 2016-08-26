module Api::V1
  class CourseGuidePeriodRepresenter < Roar::Decorator
    include Roar::JSON

    property :period_id,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { period_id.to_s }

    property :title,
             type: String,
             readable: true,
             writeable: false

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
