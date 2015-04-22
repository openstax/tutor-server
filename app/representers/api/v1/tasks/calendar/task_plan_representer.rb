module Api::V1
  module Tasks
    module Calendar
      class TaskPlanRepresenter < Api::V1::TaskPlanRepresenter

        property :stats,
                 extend: Stats::TaskPlanRepresenter,
                 getter: ->(args) { CalculateTaskPlanStats[plan: self] },
                 if: ->(args) { !published_at.nil? },
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
