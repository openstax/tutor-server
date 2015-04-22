module Api::V1
  module Tasks
    module Stats
      class TaskPlanRepresenter < Roar::Decorator

        include Roar::JSON

        property :course,
                 readable: true,
                 writeable: false,
                 decorator: CourseAndPeriodRepresenter

        collection :periods,
                   readable: true,
                   writable: false,
                   decorator: CourseAndPeriodRepresenter

      end
    end
  end
end
