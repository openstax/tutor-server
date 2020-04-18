module Api::V1::Tasks
  class TaskedExerciseGradingRepresenter < Api::V1::Tasks::TaskedExerciseRepresenter
    property :answer_id,
             inherit: true,
             writeable: false

    property :free_response,
             inherit: true,
             writeable: false

    property :response_validation,
             inherit: true,
             writeable: false

    property :grader_points,
             type: Float,
             readable: true,
             writeable: true,
             schema_info: { required: true }

    property :grader_comments,
             type: String,
             readable: true,
             writeable: true

    property :last_graded_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_graded_at) }
  end
end
