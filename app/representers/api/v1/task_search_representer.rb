module Api::V1
  class TaskSearchRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :total_count,
             type: Integer,
             getter: lambda {|*| num_matching_items},
             readable: true,
             writeable: false,
             schema_info: {
               description: "The number of tasks that match the query, can be more than the number returned"
             }

    collection :items,
               class: Task,
               decorator: Api::V1::TaskRepresenter::SubRepresenterFinder.new,
               getter: lambda {|*| tasks},
               readable: true,
               writeable: false,
               schema_info: {
                 description: "The tasks matching the query or a subset thereof when paginating"
               }
  end
end