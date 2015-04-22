module Api::V1
  module Tasks
    module Calendar
      class TaskRepresenter < Roar::Decorator

        include Roar::JSON

        property :id,
                 type: Integer,
                 readable: true

        property :title,
                 type: String,
                 readable: true

        property :opens_at,
                 type: DateTime,
                 readable: true

        property :due_at,
                 type: DateTime,
                 readable: true

        property :completed?,
                 as: :complete,
                 type: :boolean,
                 readable: true

      end
    end
  end
end
