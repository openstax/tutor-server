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

    property :content_without_correctness,
             as: :content,
             type: String,
             writeable: false,
             readable: true,
             getter: -> (*) { Exercise.new(exercise).content_without_correctness },
             schema_info: {
               required: false,
               description: "The Exercise's content without correctness and feedback info"
             }

    property :can_be_recovered,
             as: :has_recovery,
             type: 'boolean',
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             schema_info: {
               description: "Whether or not a recovery exercise is available"
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

    property :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             getter: -> (*) { Exercise.new(exercise).feedback_for(answer_id) },
             schema_info: {
               description: "The feedback given to the student"
             }

    property :correct_answer_id,
             type: String,
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             getter: -> (*) { Exercise.new(exercise).correct_question_answer_ids[0][0] },
             schema_info: {
               description: "The Exercise's correct answer's id"
             }

    property :is_correct?,
             as: :is_correct,
             type: 'boolean',
             writeable: false,
             readable: true,
             if: -> (*) { task_step.feedback_available? },
             getter: -> (*) { Exercise.new(exercise).answer_is_correct?(answer_id) },
             schema_info: {
               description: "Whether or not the answer given by the student is correct"
             }

  end
end
