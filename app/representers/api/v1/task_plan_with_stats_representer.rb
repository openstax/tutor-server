module Api::V1
  class TaskPlanWithStatsRepresenter < ::Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :type,
             type: String,
             readable: true,
             writeable: true

    property :title,
             type: String,
             readable: true,
             writeable: true

    property :description,
             type: String,
             readable: true,
             writeable: true

    collection :stats,
               extend: Api::V1::Tasks::Stats::StatRepresenter,
               getter: ->(*) { CalculateTaskStats[tasks: tasks] },
               readable: true,
               writable: false

    property :shareable_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { try(:shareable_url) || ShortCode::UrlFor[self, suffix: title] }

  end
end
