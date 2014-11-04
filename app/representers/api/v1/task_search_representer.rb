module Api::V1
  class TaskSearchRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :num_matching_items,
             as: :total_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The number of tasks that match the query, can be more than the number returned"
             }

    collection :tasks,
               as: :items,
               class: Task,
               decorator: TaskRepresenter,
               readable: true,
               writeable: false,
               schema_info: {
                 description: "The tasks matching the query or a subset thereof when paginating"
               }
  end
end