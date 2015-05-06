module Api::V1
  module Tasks
    module Calendar
      class TaskRepresenter < Roar::Decorator

        include Roar::JSON
        include Representable::Coercion

        property :id,
                 type: String,
                 readable: true,
                 writeable: false

        property :task_type,
                 as: :type,
                 type: String,
                 readable: true,
                 writeable: false

        property :title,
                 type: String,
                 readable: true,
                 writeable: false

        property :opens_at,
                 type: DateTime,
                 readable: true,
                 writeable: false

        property :due_at,
                 type: DateTime,
                 readable: true,
                 writeable: false

        property :completed?,
                 as: :complete,
                 readable: true,
                 writeable: false,
                 schema_info: { type: 'boolean' }

      end
    end
  end
end
