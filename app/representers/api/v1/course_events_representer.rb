module Api::V1

  class CourseEventsRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    collection :plans,
               readable: true,
               writeable: false,
               decorator: Api::V1::Tasks::Calendar::TaskPlanRepresenter

    collection :tasks,
               readable: true,
               writeable: false,
               decorator: Api::V1::Tasks::Calendar::TaskRepresenter

  end
end
