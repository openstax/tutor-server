module Api::V1::Metatasks
  class TaskedExerciseRepresenter < TaskStepRepresenter

    FEEDBACK_AVAILABLE = ->(*) { task_step.feedback_available? }

    property :is_two_step?,
             as: :is_two_step,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               type: 'boolean'
             }

    property :correct_answer_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The Exercise's correct answer's id"
             },
             if: FEEDBACK_AVAILABLE

    property :content_preview,
             as: :preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview as exercise tasked"
             }
  end
end
