module Api::V1::Tasks
  class TaskedExerciseRepresenter < TaskStepRepresenter

    FEEDBACK_AVAILABLE = ->(*) { task_step.feedback_available? }

    property :content_preview,
             as: :preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview as exercise tasked"
             }

    property :answer_id,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The answer id that was recorded for the Exercise"
             }

    property :uid,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The UUID of the exercise"
             }

    property :labels,
             type: Array,
             getter: ->(*) { task_step.labels },
             writeable: false,
             readable: true,
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             }

    property :formats,
             type: Array,
             getter: ->(*) { question_formats_for_students },
             writeable: false,
             readable: true,
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             }


    property :solution,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             },
             if: FEEDBACK_AVAILABLE

    property :correct_answer_id,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The Exercise's correct answer's id"
             },
             if: FEEDBACK_AVAILABLE

    property :content_hash_for_students,
             as: :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's content without attachments, vocab_term_uid, correctness, feedback or solutions"
             },
             if: INCLUDE_CONTENT

    property :garbage_estimate,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The estimate of how likely the student's free response is garbage"
             },
             if: INCLUDE_CONTENT

  end
end
