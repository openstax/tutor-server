module Api::V1

  class CourseEventsRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    collection :plans,
               readable: true,
               decorator: Tasks::Calendar::TaskPlanRepresenter

    collection :tasks,
               readable: true,
               decorator: Tasks::Calendar::TaskRepresenter

  end
end
