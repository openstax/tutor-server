module Api::V1::Tasks
  class TaskedExerciseRepresenter < TaskStepRepresenter
    FEEDBACK_AVAILABLE = ->(*) { feedback_available? }
    INCLUDE_CONTENT_AND_FEEDBACK_AVAILABLE = ->(user_options:, **) do
      user_options&.[](:include_content) && feedback_available?
    end

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of the step"
             }

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
               description: "The UUID of the exercise, steps with identical uid will be grouped together into a MPQ"
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
               description: "A list of the formats that the question should be rendered using"
             }

    property :free_response,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               required: false,
               description: "The user's free-form response to the exercise"
             },
             if: INCLUDE_CONTENT

    property :related_content,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.related_content },
             schema_info: {
               required: false,
               description: "Content related to this step",
             },
             if: INCLUDE_CONTENT

    property :feedback_available?,
             as: :is_feedback_available,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               type: 'boolean',
               description: "Whether or not this exercise's feedback is available"
             }

    property :solution,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             },
             if: INCLUDE_CONTENT_AND_FEEDBACK_AVAILABLE

    property :feedback,
             as: :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The feedback given to the student"
             },
             if: INCLUDE_CONTENT_AND_FEEDBACK_AVAILABLE

    property :correct_answer_id,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The Exercise's correct answer's id"
             },
             if: FEEDBACK_AVAILABLE

    property :context,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's context (only present if required by the Exercise)"
             },
             if: INCLUDE_CONTENT

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

    property :response_validation,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The estimate of how likely the student's free response is garbage"
             },
             if: INCLUDE_CONTENT

    property :available_points,
             type: Float,
             readable: true,
             writeable: false

    property :published_points_without_lateness,
             type: Float,
             readable: true,
             writeable: false,
             if: FEEDBACK_AVAILABLE

    property :published_late_work_point_penalty,
             type: Float,
             readable: true,
             writeable: false,
             if: FEEDBACK_AVAILABLE

    property :published_points,
             type: Float,
             readable: true,
             writeable: false,
             if: FEEDBACK_AVAILABLE

    property :published_comments,
             type: String,
             readable: true,
             writeable: false,
             if: FEEDBACK_AVAILABLE

    property :dropped,
            type: Object,
            readable: true,
            writeable: false
  end
end
