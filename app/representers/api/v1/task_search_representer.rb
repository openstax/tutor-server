module Api::V1
  class TaskSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    property :total_count,
             inherit: true,
             schema_info: {
               description: "The number of tasks that match the query, can be more than the number returned"
             }

    collection :items,
               inherit: true,
               class: Task,
               decorator: Api::V1::TaskRepresenterMapper.new,
               getter: lambda {|*| tasks.collect{|t| t.details}},
               schema_info: {
                 description: "The tasks matching the query or a subset thereof when paginating"
               }

  end
end
