module Api::V1
  class TaskSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    collection :items, inherit: true,
                       class: Task,
                       decorator: TaskRepresenter

  end
end
