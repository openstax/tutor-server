module Api::V1
  module Tasks
    module Calendar
      class TaskPlanRepresenter < ::Roar::Decorator

        include ::Roar::JSON

        property :id,
                 type: Integer,
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

        property :due_at,
                 type: String,
                 readable: true,
                 writeable: true

        property :stats,
                 extend: Stats::TaskPlanRepresenter,
                 getter: ->(args) { CalculateTaskPlanStats[plan: self] },
                 readable: true,
                 writable: false

        property :trouble,
                 type: :boolean,
                 readable: true,
                 getter: lambda{|*| rand(0..1)==0 }
        # ^^^^^ REPLACE with real value once spec for calculating it is available

      end
    end
  end
end
