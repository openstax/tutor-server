module Api::V1
  class TaskPlanSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    collection :items, inherit: true,
                       class: TaskPlan,
                       decorator: TaskPlanRepresenter

  end
end
