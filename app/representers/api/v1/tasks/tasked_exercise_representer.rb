module Api::V1::Tasks
  class TaskedExerciseRepresenter < TaskStepRepresenter

    property :url,
             as: :content_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The source URL for the Exercise containing the question being asked"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Exercise"
             }

    property :is_in_multipart,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "If true, indicates this object is part of a multipart"
             }

    property :question_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The ID of the part, present even if there is only one part."
             }

    property :context,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's context (only present if required by the Exercise)"
             }

    property :content_hash_for_students,
             as: :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's content without attachments, vocab_term_uid, correctness, feedback or solutions"
             }

    property :garbage_estimate,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The estimate of how likely the student's free response is garbage"
             }

    property :solution,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             },
             if: FEEDBACK_AVAILABLE

    property :feedback,
             as: :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The feedback given to the student"
             },
             if: FEEDBACK_AVAILABLE

    property :correct_answer_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The Exercise's correct answer's id"
             },
             if: FEEDBACK_AVAILABLE
  end
end
