module Api::V1
  class TaskPlanRepresenter < Roar::Decorator

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

    property :opens_at,
             type: String,
             readable: true,
             writeable: true

    property :published_at,
             type: String,
             readable: true,
             writeable: true

    property :due_at,
             type: String,
             readable: true,
             writeable: true

    property :settings,
             type: Object,
             readable: true,
             writeable: true

  end
end
