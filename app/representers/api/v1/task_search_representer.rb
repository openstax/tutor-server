module Api::V1
  class TaskSearchRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :query,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The query string."
             }

    property :num_matching_items,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The number of tasks that match the query, can be more than the number returned"
             }

    property :page,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The current page number of the returned results"
             }

    property :per_page,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The number of results per page"
             }

    property :order_by,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The ordering info, which may be different than what was requested if the request was missing defaults or had bad settings."
             }

    collection :tasks,
               class: Task,
               decorator: Api::V1::TaskRepresenter,
               readable: true,
               writeable: false,
               schema_info: {
                 description: "The tasks matching the query or a subset thereof when paginating"
               }

  end
end