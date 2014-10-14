module Api::V1
  class AbstractTaskRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             readable: true,
             getter: lambda {|*| self.is_a?(Task) ? id : task.id },
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda { |*| details_type.downcase },
             schema_info: {
               required: true,
               description: "The type of this Task",
               enum: ['reading']
             }

    property :task_plan_id, 
             type: Integer,
             writeable: false,
             readable: true,
             render_nil: true,
             schema_info: {
               required: false,
               description: "The ID of the TaskPlan used to generate this Task"
             }

    property :opens_at,
             type: DateTime,
             writeable: true,
             readable: true,
             schema_info: {
               type: "string",
               format: "date-time",
               required: true,
               description: "When the task is available to be worked"
             }

    property :due_at,
             type: DateTime,
             writeable: true,
             readable: true,
             schema_info: {
               type: "string",
               format: "date-time",
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