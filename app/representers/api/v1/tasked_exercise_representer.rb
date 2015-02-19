module Api::V1
  class TaskedExerciseRepresenter < Roar::Decorator

    include TaskStepProperties

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The source URL for this Exercise"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Exercise"
             }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             as: :content_json,
             schema_info: {
               required: false,
               description: "The Exercise content as JSON"
             }

    property :correct_answer_id,
             type: Integer,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.completed? }

    property :answer_id,
             type: Integer,
             writeable: true,
             readable: true

    property :free_response,
             type: String,
             writeable: true,
             readable: true

    property :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.completed? }

  end
end
