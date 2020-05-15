module Api::V1
  class CourseGuidePeriodRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :period_id,
             type: String,
             readable: true,
             writeable: false

    property :title,
             type: String,
             readable: true,
             writeable: false

    collection :page_ids,
               readable: true,
               writeable: false,
               getter: ->(*) { (page_ids || []).map(&:to_s) },
               schema_info: {
                 required: true,
                 description: "Page IDs as strings ['1', '2', ...]"
               }

    property :first_worked_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(first_worked_at) }

    property :last_worked_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_worked_at) }

    collection :children,
               readable: true,
               writeable: false,
               extend: CourseGuideChildRepresenter
  end
end
