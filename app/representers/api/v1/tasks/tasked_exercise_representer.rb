module Api::V1::Tasks
  class TaskedExerciseRepresenter < Roar::Decorator

    include TaskStepProperties

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

    property :part_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The ID of the part, present even if there is only one part."
             }

    property :content_hash_without_correct_answer,
             as: :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's content without correctness, feedback or solutions"
             }

    # The properties below assume an Exercise with only 1 Question
    property :answer_id,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The answer id given by the student"
             }

    property :free_response,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The student's free response"
             }

    property :solution,
             type: String,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             }

    property :feedback,
             as: :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             schema_info: {
               description: "The feedback given to the student"
             }

    property :correct_answer_id,
             type: String,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             schema_info: {
               description: "The Exercise's correct answer's id"
             }

    property :is_correct?,
             as: :is_correct,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             schema_info: {
               type: 'boolean',
               description: "Whether or not the answer given by the student is correct"
             }

  end
end
