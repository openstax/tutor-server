module Api::V1
  module Tasks
    module Stats
      class TaskPlanRepresenter < Roar::Decorator

        include Roar::JSON

        collection :periods,
                   readable: true,
                   writable: false,
                   decorator: Api::V1::Tasks::Stats::PeriodRepresenter

      end
    end
  end
end
