module Api::V1
  module TaskStepProperties

    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             getter: lambda { |*| task_step.id },
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda { |*| task_step.details_type.downcase },
             schema_info: {
               required: true,
               description: "The type of this TaskStep, one of: #{Api::V1::TaskStepRepresenterMapper.models.collect{|klass| "'" + klass.name.downcase + "'"}.join(',')}"
             }

    property :task_id, 
             type: Integer,
             writeable: false,
             readable: true,
             getter: lambda { |*| task_step.task_id },
             schema_info: {
               required: true,
               description: "The ID of the Task this step belongs to"
             }

    property :number, 
             type: Integer,
             writeable: true,
             readable: true,
             getter: lambda { |*| task_step.number },
             schema_info: {
               required: true,
               description: "The step number for this TaskStep"
             }

  end
end
