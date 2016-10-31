class Api::V1::TaskPlanSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

  collection :items, inherit: true,
                     class: ::Tasks::Models::TaskPlan,
                     extend: TaskPlanRepresenter

end
