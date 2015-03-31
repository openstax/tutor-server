module Api::V1
  class TaskRepresenter < Roar::Decorator

    include Roar::JSON

    property :id,
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :title,
             type: String,
             writeable: false,
             schema_info: {
               required: true
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
               description: "Whether or not the task is shared ('turn in one assignment')"
             }

    collection :task_steps,
               as: :steps,
               writeable: false,
               readable: true,
               # render and decorate the Tasked's, not the TaskSteps
               getter: -> (*) { task_steps.collect{|ts| ts.tasked} },
               decorator: Api::V1::TaskedRepresenterMapper.new,
               schema_info: {
                 required: true,
                 description: "The steps which this Task is composed of"
               }

  end
end
