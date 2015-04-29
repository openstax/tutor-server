module Api::V1
  module Tasks
    module Calendar
      class TaskPlanRepresenter < ::Roar::Decorator

        include ::Roar::JSON
        include Representable::Coercion

        property :id,
                 type: String,
                 readable: true,
                 writeable: false

        property :type,
                 type: String,
                 readable: true,
                 writeable: false

        property :title,
                 type: String,
                 readable: true,
                 writeable: false

        property :opens_at,
                 type: String,
                 readable: true,
                 writeable: false

        property :due_at,
                 type: String,
                 readable: true,
                 writeable: false

        property :trouble,
                 readable: true,
                 writeable: false,
                 getter: lambda{ |*| rand(0..1)==0 },
                 schema_info: { type: 'boolean' }
        # ^^^^^ REPLACE with real value once spec for calculating it is available

      end
    end
  end
end
