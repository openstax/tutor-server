module Api::V1
  class TaskedExerciseRepresenter < Roar::Decorator

    include TaskStepProperties

    property :correct_answer_id,
             type: Integer,
             writeable: false,
             readable: true,
             skip_render: -> (*) { !task_step.completed? }

    property :answer_id,
             type: Integer,
             writeable: true,
             readable: true,
             skip_render: -> (*) { answer_id.blank? }

    property :free_response,
             type: String,
             writeable: true,
             readable: true,
             skip_render: -> (*) { free_response.blank? }

    property :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             skip_render: -> (*) { !task_step.completed? }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             getter: -> (*) { ::JSON.parse(task_step.content) },
             schema_info: {
               required: false,
               description: "The exercise content as JSON"
             }
  end
end
