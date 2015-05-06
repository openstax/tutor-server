module Api::V1::Tasks
  class TaskedExerciseRepresenter < Roar::Decorator

    include TaskStepProperties
    include Representable::Coercion

    property :url,
             as: :content_url,
             type: String,
             writeable: false,
             readable: true,
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

    property :content_hash_without_correctness,
             as: :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's content without correctness and feedback info"
             }

    property :can_be_recovered?,
             as: :has_recovery,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             schema_info: {
               type: 'boolean',
               description: "Whether or not a recovery exercise is available"
             }

    property :group_name,
             as: :group,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.group_name },
             schema_info: {
                description: "Which exercise group the exercise belongs to (default,core,spaced practice,personalized)"
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

    ## TODO: Move this to TaskStepProperties
    collection :related_content,
               writeable: false,
               readable: true,
               # decorator: TaskStepRepresenter,
               getter: lambda {|*| task_step.related_content },
               schema_info: {
                 required: true,
                 description: "Misc information related to this exercise"
               }

  end
end
