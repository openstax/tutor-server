module Api::V1
  module Tasks
    module Stats
      class TaskPlanRepresenter < Roar::Decorator

        include Roar::JSON

        property :course,
                 readable: true,
                 writeable: false,
                 decorator: Api::V1::Tasks::Stats::CourseAndPeriodRepresenter

        collection :periods,
                   readable: true,
                   writable: false,
                   decorator: Api::V1::Tasks::Stats::CourseAndPeriodRepresenter

      end
    end
  end
end
