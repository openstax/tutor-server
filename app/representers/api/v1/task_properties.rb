module Api::V1
  module TaskProperties
    
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             getter: lambda {|*| task.id },
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda {|*| type.downcase },
             schema_info: {
               required: true,
               description: "The type of this Task, one of: #{Api::V1::TaskRepresenterMapper.models.collect{|klass| "'" + klass.name.downcase + "'"}.join(',')}"
             }

    property :task_plan_id, 
             type: Integer,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The ID of the TaskPlan used to generate this Task"
             }

    property :opens_at,
             type: DateTime,
             writeable: true,
             readable: true,
             schema_info: {
               required: true,
               description: "When the task is available to be worked"
             }

    property :due_at,
             type: DateTime,
             writeable: true,
             readable: true,
             schema_info: {
               required: true,
               description: "When the task is due (nil means not due)"
             }

    property :is_shared,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "Whether or not the detailed task is shared ('turn in one assignment')"
             }




  end
end